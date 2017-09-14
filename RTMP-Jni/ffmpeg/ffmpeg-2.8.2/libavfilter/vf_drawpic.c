/*
 * Copyright (c) 2011 Stefano Sabatini
 * Copyright (c) 2010 S.N. Hemanth Meenakshisundaram
 * Copyright (c) 2003 Gustavo Sverzut Barbieri <gsbarbieri@yahoo.com.br>
 *
 * This file is part of FFmpeg.
 *
 * FFmpeg is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * FFmpeg is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with FFmpeg; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA
 */

/**
 * @file
 * drawtext filter, based on the original vhook/drawtext.c
 * filter by Gustavo Sverzut Barbieri
 */

#include "config.h"

#if HAVE_SYS_TIME_H
#include <sys/time.h>
#endif
#include <sys/types.h>
#include <sys/stat.h>
#include <time.h>
#if HAVE_UNISTD_H
#include <unistd.h>
#endif
#include <fenv.h>

#include "libavutil/avstring.h"
#include "libavutil/bprint.h"
#include "libavutil/common.h"
#include "libavutil/file.h"
#include "libavutil/opt.h"
#include "libavutil/random_seed.h"
#include "libavutil/parseutils.h"
#include "libavutil/timecode.h"
#include "libavutil/time_internal.h"
#include "libavutil/tree.h"
#include "libavutil/lfg.h"
#include "avfilter.h"
#include "drawutils.h"
#include "formats.h"
#include "internal.h"
#include "video.h"
#include "libavutil/frame.h"
#include "libavcodec/avcodec.h"  
#include "libavformat/avformat.h"  
#include "libswscale/swscale.h"  

typedef struct DrawPicContext {
    const AVClass *class;
    uint8_t *picfile;               ///< picture file path
    int x;                          ///< x position to start drawing picture
    int y;                          ///< y position to start drawing picture
	
	AVFrame* bgPicture;
} DrawPicContext;

#define OFFSET(x) offsetof(DrawPicContext, x)
#define FLAGS AV_OPT_FLAG_FILTERING_PARAM|AV_OPT_FLAG_VIDEO_PARAM

static const AVOption drawpic_options[]= {
    {"picfile",    "set picture file",        OFFSET(picfile),           AV_OPT_TYPE_STRING, {.str=NULL},  CHAR_MIN, CHAR_MAX, FLAGS},
    {"x",     		"set x",                OFFSET(x),            AV_OPT_TYPE_INT,    {.i64=0},     INT_MIN,  INT_MAX , FLAGS},
    {"y",     		"set y",                OFFSET(y),            AV_OPT_TYPE_INT,    {.i64=0},     INT_MIN,  INT_MAX , FLAGS},
    { NULL }
};

AVFILTER_DEFINE_CLASS(drawpic);

static inline int is_newline(uint32_t c)
{
    return c == '\n' || c == '\r' || c == '\f' || c == '\v';
}

static int decode_picture(AVFilterContext *ctx)
{
	DrawPicContext *s = ctx->priv;
	int ret = 0;
	int decodeRet = -1;
	unsigned int i;
	AVFrame* pFrame = NULL;
	AVCodecContext *codecCtx = NULL;
	int videoIdx = -1;
	AVPacket packet;
	AVFormatContext* fmtCtx = NULL;

	fmtCtx = avformat_alloc_context();
	if ((ret = avformat_open_input(&fmtCtx, s->picfile, NULL, NULL)) < 0) {
		av_log(NULL, AV_LOG_ERROR, "Cannot open input file.\n");
		goto ErrTag;
	}

	if ((ret = avformat_find_stream_info(fmtCtx, NULL)) < 0) {
		av_log(NULL, AV_LOG_ERROR, "Cannot find stream information.\n");
		goto ErrTag;
	}
	
	for (i = 0; i < fmtCtx->nb_streams; i++) {
		codecCtx = fmtCtx->streams[i]->codec;
		if (codecCtx->codec_type == AVMEDIA_TYPE_VIDEO) {
			/* Open decoder */
			AVCodec* pcodec = avcodec_find_decoder(codecCtx->codec_id);
			if(!pcodec) {
				av_log(NULL, AV_LOG_ERROR, "Cannot find codec:%d.\n", codecCtx->codec_id);
				goto ErrTag;
			}
			ret = avcodec_open2(codecCtx, pcodec, NULL);
			if (ret < 0) {
				av_log(NULL, AV_LOG_ERROR, "Failed to open decoder for video.\n");
				goto ErrTag;
			}
			videoIdx = i;
			break;
		}
	}

	if (videoIdx < 0) {
		goto ErrTag;
	}

	if ((ret = av_read_frame(fmtCtx, &packet)) < 0) {
		av_log(NULL, AV_LOG_ERROR, "Read frame failed.\n");
		goto ErrTag;
	}
	
	int gotFrame = 0;
	pFrame = av_frame_alloc();
	if (!pFrame) {
		av_log(NULL, AV_LOG_ERROR, "alloc_frame failed.\n");
		goto ErrTag;
	}
	
	ret = avcodec_decode_video2(codecCtx, pFrame, &gotFrame, &packet);
	if (ret >= 0) {
		if(!gotFrame) {
			av_free_packet(&packet);
			packet.data = NULL;
			packet.size = 0;
			ret = avcodec_decode_video2(codecCtx, pFrame, &gotFrame, &packet);
		}
		if(gotFrame) {
			decodeRet = 0;
		}
	}
	
	if(!gotFrame) {
		av_log(NULL, AV_LOG_ERROR, "Decode video frame failed:code:%d, gotFrame:%d.\n", ret, gotFrame);
		goto ErrTag;
	}
	
	int w = codecCtx->width, h = codecCtx->height;
	s->bgPicture = av_frame_alloc();
	if (!s->bgPicture) {
		av_log(NULL, AV_LOG_ERROR, "alloc_frame failed in .\n");
		return NULL;
	}
	
	av_log(ctx, AV_LOG_INFO, "Frame size:%dx%d, pix_fmt:%d.\n", w,h,codecCtx->pix_fmt);
	s->bgPicture->width = w;
	s->bgPicture->height = h;
	s->bgPicture->format = AV_PIX_FMT_YUVA420P;
	av_frame_get_buffer(s->bgPicture, 16);

	struct SwsContext* pSwScale = sws_getContext(w, h, codecCtx->pix_fmt,
					 w, h, AV_PIX_FMT_YUVA420P, SWS_FAST_BILINEAR, NULL, NULL, NULL);
	sws_scale(pSwScale, pFrame->data, pFrame->linesize,
			0, h, s->bgPicture->data, s->bgPicture->linesize);
	sws_freeContext(pSwScale);
	av_log(ctx, AV_LOG_INFO, "Complete getting picture frame.\n");
ErrTag:
	av_free_packet(&packet);
	if(pFrame) av_frame_free(&pFrame);
	if(fmtCtx) {
		if (videoIdx >= 0 && codecCtx) {
			avcodec_close(codecCtx);
		}
		avformat_close_input(&fmtCtx);
	}
	
	return decodeRet;
}

#define FAST_DIV255(x) ((((x) + 128) * 257) >> 16)
/**
 * Blend image in src to destination buffer dst at position (x, y).
 */
static void blend_image(AVFrame *dst, const AVFrame *src,
                        int x, int y)
{
    const int src_w = src->width;
    const int src_h = src->height;
    const int dst_w = dst->width;
    const int dst_h = dst->height;

    if (x >= dst_w || x+src_w < 0 ||
        y >= dst_h || y+src_h < 0)
        return; /* no intersection */
	int i, j;
	
	for(i=0; i<src_h; ++i) {
		for(j=0; j<src_w; ++j) {
			int dstYIdx = (i+x)*dst->linesize[0]+j+y;
			int srcYIdx = i*src->linesize[0]+j;
			int dstUVIdx = ((i+x)*dst->linesize[1]+j+y)>>1;
			int srcUVIdx = (i*src->linesize[1]+j)>>1;
			int alpha = src->data[3][srcYIdx];
			
			if(alpha != 255) {
				dst->data[0][dstYIdx] = FAST_DIV255(dst->data[0][dstYIdx] * (255 - alpha) + src->data[0][srcYIdx] * alpha); ;
				if(i%2 == 0 && j%2 == 0) {
					dst->data[1][dstUVIdx] = FAST_DIV255(dst->data[1][dstUVIdx] * (255 - alpha) + src->data[1][srcUVIdx] * alpha);
					dst->data[2][dstUVIdx] = FAST_DIV255(dst->data[2][dstUVIdx] * (255 - alpha) + src->data[2][srcUVIdx] * alpha);
				} 
			} else {
				dst->data[0][dstYIdx] = src->data[0][srcYIdx];
				if(i%2 == 0 && j%2 == 0) {
					dst->data[1][dstUVIdx] = src->data[1][srcUVIdx];
					dst->data[2][dstUVIdx] = src->data[2][srcUVIdx];
				} 
			}
			
		}
	}
}

static int query_formats(AVFilterContext *ctx)
{
    return ff_set_common_formats(ctx, ff_draw_supported_pixel_formats(0));
}

static av_cold int init(AVFilterContext *ctx)
{
    //int err;
    //DrawPicContext *s = ctx->priv;
    return decode_picture(ctx);
}

static av_cold void uninit(AVFilterContext *ctx)
{
    DrawPicContext *s = ctx->priv;
	av_frame_free(&s->bgPicture);
}

/*
static int config_input(AVFilterLink *inlink)
{
    AVFilterContext *ctx = inlink->dst;
    DrawPicContext *s = ctx->priv;
    return 0;
}*/

static int command(AVFilterContext *ctx, const char *cmd, const char *arg, char *res, int res_len, int flags)
{
    /*DrawPicContext *s = ctx->priv;

    if (!strcmp(cmd, "reinit")) {
        int ret;
        uninit(ctx);
        if ((ret = av_set_options_string(ctx, arg, "=", ":")) < 0)
            return ret;
        
        return config_input(ctx->inputs[0]);
    }*/

    return AVERROR(ENOSYS);
}

static int draw_pic(AVFilterContext *ctx, AVFrame *frame,
                     int width, int height)
{
    DrawPicContext *s = ctx->priv;
	blend_image(frame, s->bgPicture, s->x, s->y);
    return 0;
}

static int filter_frame(AVFilterLink *inlink, AVFrame *frame)
{
    AVFilterContext *ctx = inlink->dst;
    AVFilterLink *outlink = ctx->outputs[0];
    DrawPicContext *s = ctx->priv;
    draw_pic(ctx, frame, frame->width, frame->height);
    return ff_filter_frame(outlink, frame);
}

static const AVFilterPad avfilter_vf_drawpic_inputs[] = {
    {
        .name           = "default",
        .type           = AVMEDIA_TYPE_VIDEO,
        .filter_frame   = filter_frame,
        //.config_props   = config_input,
        .needs_writable = 1,
    },
    { NULL }
};

static const AVFilterPad avfilter_vf_drawpic_outputs[] = {
    {
        .name = "default",
        .type = AVMEDIA_TYPE_VIDEO,
    },
    { NULL }
};

AVFilter ff_vf_drawpic = {
    .name          = "drawpic",
    .description   = NULL_IF_CONFIG_SMALL("Draw pictiure on top of video frames."),
    .priv_size     = sizeof(DrawPicContext),
    .priv_class    = &drawpic_class,
    .init          = init,
    .uninit        = uninit,
    .query_formats = query_formats,
    .inputs        = avfilter_vf_drawpic_inputs,
    .outputs       = avfilter_vf_drawpic_outputs,
    .process_command = command,
    .flags         = AVFILTER_FLAG_SUPPORT_TIMELINE_GENERIC,
};

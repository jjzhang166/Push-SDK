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

#if CONFIG_LIBFONTCONFIG
#include <fontconfig/fontconfig.h>
#endif

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
#include "libavutil/frame.h"
#include "libavcodec/avcodec.h"  
#include "libavformat/avformat.h"  
#include "libswscale/swscale.h"  

#include "avfilter.h"
#include "drawutils.h"
#include "formats.h"
#include "internal.h"
#include "video.h"

#if CONFIG_LIBFRIBIDI
#include <fribidi.h>
#endif

#include <ft2build.h>
#include FT_FREETYPE_H
#include FT_GLYPH_H
#include FT_STROKER_H

typedef struct DrawPosterContext {
    const AVClass *class;
	char *picfileStr;               ///< multiple picture files path split by '|', eg:"e:\\pic1.png|e:\\pic2.png"
    char *picPosStr;                ///< multiple picture positions split by '|', eg:"30\,30|40\,40"
	char *picSizeStr;                	///< multiple picture size split by '|', eg:"100\,80|200\,50"
	
	char* fontfile;
	char* textStr;					///< multiple texts split by '|', eg:"上海|北京|杭州"
	char* textPosStr;				///< multiple positions split by '|', eg:"30\,30|40\,40|60\,60"
	
	int frames;						///< specify how many frames to render
	int borderw;                    ///< border width
	int shadowx, shadowy;
    unsigned int fontsize;          ///< font size to use
    short int draw_box;             ///< draw box around text - true or false
    int boxborderw;                 ///< box border width
    int use_kerning;                ///< font kerning is used - true/false
    int tabsize;                    ///< tab size
	
    int fix_bounds;                 ///< do we let it go out of frame bounds - t/f
    FFDrawContext dc;
    FFDrawColor fontcolor;          ///< foreground color
    FFDrawColor shadowcolor;        ///< shadow color
    FFDrawColor bordercolor;        ///< border color
    FFDrawColor boxcolor;           ///< background color
	uint8_t textAlpha;				///< text alpha
	int ft_load_flags;
#if CONFIG_LIBFONTCONFIG
    char *font;              		///< font to be used
#endif
#if CONFIG_LIBFRIBIDI
    int text_shaping;               ///< 1 to shape the text before drawing it
#endif
	FT_Library library;             ///< freetype font library handle
    FT_Face face;                   ///< freetype font face handle
    FT_Stroker stroker;             ///< freetype stroker handle
    struct AVTreeNode *glyphs;      ///< rendered glyphs, stored using the UTF-32 char code
	int max_glyph_w;                ///< max glyph width
    int max_glyph_h;                ///< max glyph height
	
	int renderFramesCounter;		///< count frame rendered
	char** textArr;
	FT_Vector* textPos;
	int textNum;
	
	FT_Vector *chRelativePos;       ///< chRelativePos for each element in current text
    size_t nb_chRelativePos;        ///< number of elements of chRelativePos array
	
	AVFrame** picArr;				///< picture frames array
	FT_Vector* picPos;				///< picture position array
	FT_Vector* picSize;				///< picture size array
	int picNum;
} DrawPosterContext;

#define OFFSET(x) offsetof(DrawPosterContext, x)
#define FLAGS AV_OPT_FLAG_FILTERING_PARAM|AV_OPT_FLAG_VIDEO_PARAM

static const AVOption drawposter_options[]= {
    {"picfile",    "set picture files",         OFFSET(picfileStr),         AV_OPT_TYPE_STRING, {.str=NULL},  CHAR_MIN, CHAR_MAX, FLAGS},
    {"picpos",     "set picture position",  	OFFSET(picPosStr),            AV_OPT_TYPE_STRING, {.str=NULL},  CHAR_MIN, CHAR_MAX, FLAGS},
	{"picsize",    "set picture size",  		OFFSET(picSizeStr),            AV_OPT_TYPE_STRING, {.str=NULL},  CHAR_MIN, CHAR_MAX, FLAGS},
	{"frames",     "set render frames num",     OFFSET(frames),          AV_OPT_TYPE_INT,    {.i64=0},     0,  INT_MAX , FLAGS},
	{"fontfile",    "set font file",        OFFSET(fontfile),           AV_OPT_TYPE_STRING, {.str=NULL},  CHAR_MIN, CHAR_MAX, FLAGS},
    {"text",        "set text string",      OFFSET(textStr),               AV_OPT_TYPE_STRING, {.str=NULL},  CHAR_MIN, CHAR_MAX, FLAGS},
	{"textpos",     "set text pos string",  OFFSET(textPosStr),               AV_OPT_TYPE_STRING, {.str=NULL},  CHAR_MIN, CHAR_MAX, FLAGS},
    {"fontcolor",   "set foreground color", OFFSET(fontcolor.rgba),     AV_OPT_TYPE_COLOR,  {.str="black"}, CHAR_MIN, CHAR_MAX, FLAGS},
    {"boxcolor",    "set box color",        OFFSET(boxcolor.rgba),      AV_OPT_TYPE_COLOR,  {.str="white"}, CHAR_MIN, CHAR_MAX, FLAGS},
    {"bordercolor", "set border color",     OFFSET(bordercolor.rgba),   AV_OPT_TYPE_COLOR,  {.str="black"}, CHAR_MIN, CHAR_MAX, FLAGS},
    {"shadowcolor", "set shadow color",     OFFSET(shadowcolor.rgba),   AV_OPT_TYPE_COLOR,  {.str="black"}, CHAR_MIN, CHAR_MAX, FLAGS},
    {"box",         "set box",              OFFSET(draw_box),           AV_OPT_TYPE_INT,    {.i64=0},     0,        1       , FLAGS},
    {"boxborderw",  "set box border width", OFFSET(boxborderw),         AV_OPT_TYPE_INT,    {.i64=0},     INT_MIN,  INT_MAX , FLAGS},
    {"fontsize",    "set font size",        OFFSET(fontsize),           AV_OPT_TYPE_INT,    {.i64=0},     0,        INT_MAX , FLAGS},
    {"shadowx",     "set x",                OFFSET(shadowx),            AV_OPT_TYPE_INT,    {.i64=0},     INT_MIN,  INT_MAX , FLAGS},
    {"shadowy",     "set y",                OFFSET(shadowy),            AV_OPT_TYPE_INT,    {.i64=0},     INT_MIN,  INT_MAX , FLAGS},
    {"borderw",     "set border width",     OFFSET(borderw),            AV_OPT_TYPE_INT,    {.i64=0},     INT_MIN,  INT_MAX , FLAGS},
    {"tabsize",     "set tab size",         OFFSET(tabsize),            AV_OPT_TYPE_INT,    {.i64=4},     0,        INT_MAX , FLAGS},
	{"alpha",       "apply text alpha",     OFFSET(textAlpha),          AV_OPT_TYPE_INT,    {.i64=255},   0,     	255     , FLAGS },
    {"fix_bounds", "if true, check and fix text coords to avoid clipping",  OFFSET(fix_bounds), AV_OPT_TYPE_INT, {.i64=1}, 0, 1, FLAGS},
	
	#if CONFIG_LIBFRIBIDI
    {"text_shaping", "attempt to shape text before drawing", OFFSET(text_shaping), AV_OPT_TYPE_INT, {.i64=1}, 0, 1, FLAGS},
#endif

    /* FT_LOAD_* flags */
    { "ft_load_flags", "set font loading flags for libfreetype", OFFSET(ft_load_flags), AV_OPT_TYPE_FLAGS, { .i64 = FT_LOAD_DEFAULT }, 0, INT_MAX, FLAGS, "ft_load_flags" },
        { "default",                     NULL, 0, AV_OPT_TYPE_CONST, { .i64 = FT_LOAD_DEFAULT },                     .flags = FLAGS, .unit = "ft_load_flags" },
        { "no_scale",                    NULL, 0, AV_OPT_TYPE_CONST, { .i64 = FT_LOAD_NO_SCALE },                    .flags = FLAGS, .unit = "ft_load_flags" },
        { "no_hinting",                  NULL, 0, AV_OPT_TYPE_CONST, { .i64 = FT_LOAD_NO_HINTING },                  .flags = FLAGS, .unit = "ft_load_flags" },
        { "render",                      NULL, 0, AV_OPT_TYPE_CONST, { .i64 = FT_LOAD_RENDER },                      .flags = FLAGS, .unit = "ft_load_flags" },
        { "no_bitmap",                   NULL, 0, AV_OPT_TYPE_CONST, { .i64 = FT_LOAD_NO_BITMAP },                   .flags = FLAGS, .unit = "ft_load_flags" },
        { "vertical_layout",             NULL, 0, AV_OPT_TYPE_CONST, { .i64 = FT_LOAD_VERTICAL_LAYOUT },             .flags = FLAGS, .unit = "ft_load_flags" },
        { "force_autohint",              NULL, 0, AV_OPT_TYPE_CONST, { .i64 = FT_LOAD_FORCE_AUTOHINT },              .flags = FLAGS, .unit = "ft_load_flags" },
        { "crop_bitmap",                 NULL, 0, AV_OPT_TYPE_CONST, { .i64 = FT_LOAD_CROP_BITMAP },                 .flags = FLAGS, .unit = "ft_load_flags" },
        { "pedantic",                    NULL, 0, AV_OPT_TYPE_CONST, { .i64 = FT_LOAD_PEDANTIC },                    .flags = FLAGS, .unit = "ft_load_flags" },
        { "ignore_global_advance_width", NULL, 0, AV_OPT_TYPE_CONST, { .i64 = FT_LOAD_IGNORE_GLOBAL_ADVANCE_WIDTH }, .flags = FLAGS, .unit = "ft_load_flags" },
        { "no_recurse",                  NULL, 0, AV_OPT_TYPE_CONST, { .i64 = FT_LOAD_NO_RECURSE },                  .flags = FLAGS, .unit = "ft_load_flags" },
        { "ignore_transform",            NULL, 0, AV_OPT_TYPE_CONST, { .i64 = FT_LOAD_IGNORE_TRANSFORM },            .flags = FLAGS, .unit = "ft_load_flags" },
        { "monochrome",                  NULL, 0, AV_OPT_TYPE_CONST, { .i64 = FT_LOAD_MONOCHROME },                  .flags = FLAGS, .unit = "ft_load_flags" },
        { "linear_design",               NULL, 0, AV_OPT_TYPE_CONST, { .i64 = FT_LOAD_LINEAR_DESIGN },               .flags = FLAGS, .unit = "ft_load_flags" },
        { "no_autohint",                 NULL, 0, AV_OPT_TYPE_CONST, { .i64 = FT_LOAD_NO_AUTOHINT },                 .flags = FLAGS, .unit = "ft_load_flags" },
    { NULL }
};

AVFILTER_DEFINE_CLASS(drawposter);

static inline int is_newline(uint32_t c)
{
    return c == '\n' || c == '\r' || c == '\f' || c == '\v';
}

static int decode_picture(DrawPosterContext *s, char* picfile, AVFrame* pDstFrame)
{
	int ret = 0;
	int decodeRet = -1;
	unsigned int i;
	AVCodecContext *codecCtx = NULL;
	int videoIdx = -1;
	AVPacket packet;
	AVFormatContext* fmtCtx = NULL;
	AVFrame* pFrame = NULL;
	
	fmtCtx = avformat_alloc_context();
	if ((ret = avformat_open_input(&fmtCtx, picfile, NULL, NULL)) < 0) {
		av_log(NULL, AV_LOG_ERROR, "Cannot open input file:%s.\n", picfile);
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
		av_log(s, AV_LOG_ERROR, "Decode video frame failed:code:%d, gotFrame:%d.\n", ret, gotFrame);
		goto ErrTag;
	}
	
	int w = codecCtx->width, h = codecCtx->height;
	if(pDstFrame->width == 0 || pDstFrame->height == 0) {
		pDstFrame->width = w;
		pDstFrame->height = h;
	}
	pDstFrame->format = AV_PIX_FMT_YUVA420P;
	av_frame_get_buffer(pDstFrame, 16);

	struct SwsContext* pSwScale = sws_getContext(w, h, codecCtx->pix_fmt,
					 pDstFrame->width, pDstFrame->height, AV_PIX_FMT_YUVA420P, SWS_FAST_BILINEAR, NULL, NULL, NULL);
	sws_scale(pSwScale, pFrame->data, pFrame->linesize,
			0, h, pDstFrame->data, pDstFrame->linesize);
	sws_freeContext(pSwScale);
	av_log(s, AV_LOG_INFO, "Complete getting picture frame.\n");
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
	if(x % 2 != 0) {
		x -= 1;
	}
	if(y % 2 != 0) {
		y -= 1;
	}
	
	int i, j;
	
	for(i=0; i<src_h; ++i) {
		if(i+y >= dst_h) break;
		uint8_t* pSrcY = src->data[0] + i*src->linesize[0];
		uint8_t* pDstY = dst->data[0] + ((i+y)*dst->linesize[0] + x);
		uint8_t* pSrcU = src->data[1] + (i>>1)*src->linesize[1];
		uint8_t* pDstU = dst->data[1] + (((i+y)>>1)*dst->linesize[1] + (x>>1));
		uint8_t* pSrcV = src->data[2] + (i>>1)*src->linesize[2];
		uint8_t* pDstV = dst->data[2] + (((i+y)>>1)*dst->linesize[2] + (x>>1));
		uint8_t* pSrcA = src->data[3] + i*src->linesize[3];
		j = 0;
		while(j < src_w) {
			if(j+x >= dst_w) break;
			uint8_t alpha = *pSrcA++;
			if(alpha != 255) {		// alpha
				uint8_t curY = *pDstY;
				uint8_t mainAlpha = 255-alpha;
				*pDstY = FAST_DIV255(curY*mainAlpha + (*pSrcY)*alpha);
				pDstY++;  pSrcY++;
				if(i%2 == 0 && j%2 == 0) {
					uint8_t curU = *pDstU;
					uint8_t curV = *pDstV;
					*pDstU = FAST_DIV255(curU*mainAlpha + (*pSrcU)*alpha);
					*pDstV = FAST_DIV255(curV*mainAlpha + (*pSrcV)*alpha);
					pDstU++; pSrcU++;
					pDstV++; pSrcV++;
				}
			} else {
				*pDstY++ = *pSrcY++;
				if(i%2 == 0 && j%2 == 0) {
					*pDstU++ = *pSrcU++;
					*pDstV++ = *pSrcV++;
				}
			}
			++j;
		}
	}
}

#undef __FTERRORS_H__
#define FT_ERROR_START_LIST {
#define FT_ERRORDEF(e, v, s) { (e), (s) },
#define FT_ERROR_END_LIST { 0, NULL } };

static const struct ft_error
{
    int err;
    const char *err_msg;
} ft_errors[] =
#include FT_ERRORS_H

#define FT_ERRMSG(e) ft_errors[e].err_msg

typedef struct Glyph {
    FT_Glyph glyph;
    FT_Glyph border_glyph;
    uint32_t code;
    FT_Bitmap bitmap; ///< array holding bitmaps of font
    FT_Bitmap border_bitmap; ///< array holding bitmaps of font border
    FT_BBox bbox;
    int advance;
    int bitmap_left;
    int bitmap_top;
} Glyph;

static int glyph_cmp(void *key, const void *b)
{
    const Glyph *a = key, *bb = b;
    int64_t diff = (int64_t)a->code - (int64_t)bb->code;
    return diff > 0 ? 1 : diff < 0 ? -1 : 0;
}

/**
 * Load glyphs corresponding to the UTF-32 codepoint code.
 */
static int load_glyph(AVFilterContext *ctx, Glyph **glyph_ptr, uint32_t code)
{
    DrawPosterContext *s = ctx->priv;
    FT_BitmapGlyph bitmapglyph;
    Glyph *glyph;
    struct AVTreeNode *node = NULL;
    int ret;

    /* load glyph into s->face->glyph */
    if (FT_Load_Char(s->face, code, s->ft_load_flags))
        return AVERROR(EINVAL);

    glyph = av_mallocz(sizeof(*glyph));
    if (!glyph) {
        ret = AVERROR(ENOMEM);
        goto error;
    }
    glyph->code  = code;

    if (FT_Get_Glyph(s->face->glyph, &glyph->glyph)) {
        ret = AVERROR(EINVAL);
        goto error;
    }
    if (s->borderw) {
        glyph->border_glyph = glyph->glyph;
        if (FT_Glyph_StrokeBorder(&glyph->border_glyph, s->stroker, 0, 0) ||
            FT_Glyph_To_Bitmap(&glyph->border_glyph, FT_RENDER_MODE_NORMAL, 0, 1)) {
            ret = AVERROR_EXTERNAL;
            goto error;
        }
        bitmapglyph = (FT_BitmapGlyph) glyph->border_glyph;
        glyph->border_bitmap = bitmapglyph->bitmap;
    }
    if (FT_Glyph_To_Bitmap(&glyph->glyph, FT_RENDER_MODE_NORMAL, 0, 1)) {
        ret = AVERROR_EXTERNAL;
        goto error;
    }
    bitmapglyph = (FT_BitmapGlyph) glyph->glyph;

    glyph->bitmap      = bitmapglyph->bitmap;
    glyph->bitmap_left = bitmapglyph->left;
    glyph->bitmap_top  = bitmapglyph->top;
    glyph->advance     = s->face->glyph->advance.x >> 6;

    /* measure text height to calculate text_height (or the maximum text height) */
    FT_Glyph_Get_CBox(glyph->glyph, ft_glyph_bbox_pixels, &glyph->bbox);

    /* cache the newly created glyph */
    if (!(node = av_tree_node_alloc())) {
        ret = AVERROR(ENOMEM);
        goto error;
    }
    av_tree_insert(&s->glyphs, glyph, glyph_cmp, &node);

    if (glyph_ptr)
        *glyph_ptr = glyph;
    return 0;

error:
    if (glyph)
        av_freep(&glyph->glyph);

    av_freep(&glyph);
    av_freep(&node);
    return ret;
}

static int load_font_file(AVFilterContext *ctx, const char *path, int index)
{
    DrawPosterContext *s = ctx->priv;
    int err;

    err = FT_New_Face(s->library, path, index, &s->face);
    if (err) {
        av_log(ctx, AV_LOG_ERROR, "Could not load font \"%s\": %s\n",
               s->fontfile, FT_ERRMSG(err));
        return AVERROR(EINVAL);
    }
    return 0;
}

#if CONFIG_LIBFONTCONFIG
static int load_font_fontconfig(AVFilterContext *ctx)
{
    DrawPosterContext *s = ctx->priv;
    FcConfig *fontconfig;
    FcPattern *pat, *best;
    FcResult result = FcResultMatch;
    FcChar8 *filename;
    int index;
    double size;
    int err = AVERROR(ENOENT);

    fontconfig = FcInitLoadConfigAndFonts();
    if (!fontconfig) {
        av_log(ctx, AV_LOG_ERROR, "impossible to init fontconfig\n");
        return AVERROR_UNKNOWN;
    }
    pat = FcNameParse(s->fontfile ? s->fontfile :
                          (uint8_t *)(intptr_t)"default");
    if (!pat) {
        av_log(ctx, AV_LOG_ERROR, "could not parse fontconfig pat");
        return AVERROR(EINVAL);
    }

    FcPatternAddString(pat, FC_FAMILY, s->font);
    if (s->fontsize)
        FcPatternAddDouble(pat, FC_SIZE, (double)s->fontsize);

    FcDefaultSubstitute(pat);

    if (!FcConfigSubstitute(fontconfig, pat, FcMatchPattern)) {
        av_log(ctx, AV_LOG_ERROR, "could not substitue fontconfig options"); /* very unlikely */
        FcPatternDestroy(pat);
        return AVERROR(ENOMEM);
    }

    best = FcFontMatch(fontconfig, pat, &result);
    FcPatternDestroy(pat);

    if (!best || result != FcResultMatch) {
        av_log(ctx, AV_LOG_ERROR,
               "Cannot find a valid font for the family %s\n",
               s->font);
        goto fail;
    }

    if (
        FcPatternGetInteger(best, FC_INDEX, 0, &index   ) != FcResultMatch ||
        FcPatternGetDouble (best, FC_SIZE,  0, &size    ) != FcResultMatch) {
        av_log(ctx, AV_LOG_ERROR, "impossible to find font information");
        return AVERROR(EINVAL);
    }

    if (FcPatternGetString(best, FC_FILE, 0, &filename) != FcResultMatch) {
        av_log(ctx, AV_LOG_ERROR, "No file path for %s\n",
               s->font);
        goto fail;
    }

    av_log(ctx, AV_LOG_INFO, "Using \"%s\"\n", filename);
    if (!s->fontsize)
        s->fontsize = size + 0.5;

    err = load_font_file(ctx, filename, index);
    if (err)
        return err;
    FcConfigDestroy(fontconfig);
fail:
    FcPatternDestroy(best);
    return err;
}
#endif

static int load_font(AVFilterContext *ctx)
{
    DrawPosterContext *s = ctx->priv;
    int err;

    /* load the face, and set up the encoding, which is by default UTF-8 */
    err = load_font_file(ctx, s->fontfile, 0);
    if (!err)
        return 0;
#if CONFIG_LIBFONTCONFIG
    err = load_font_fontconfig(ctx);
    if (!err)
        return 0;
#endif
    return err;
}

static void update_color_with_alpha(DrawPosterContext *s, FFDrawColor *color, const FFDrawColor incolor)
{
    *color = incolor;
    color->rgba[3] = (color->rgba[3] * s->textAlpha) / 255;
    ff_draw_color(&s->dc, color, color->rgba);
}

static int query_formats(AVFilterContext *ctx)
{
    return ff_set_common_formats(ctx, ff_draw_supported_pixel_formats(0));
}
#if CONFIG_LIBFRIBIDI
static int shape_text(char** text)
{
    uint8_t *tmp;
    int ret = AVERROR(ENOMEM);
    static const FriBidiFlags flags = FRIBIDI_FLAGS_DEFAULT |
                                      FRIBIDI_FLAGS_ARABIC;
    FriBidiChar *unicodestr = NULL;
    FriBidiStrIndex len;
    FriBidiParType direction = FRIBIDI_PAR_LTR;
    FriBidiStrIndex line_start = 0;
    FriBidiStrIndex line_end = 0;
    FriBidiLevel *embedding_levels = NULL;
    FriBidiArabicProp *ar_props = NULL;
    FriBidiCharType *bidi_types = NULL;
    FriBidiStrIndex i,j;

    len = strlen(*text);
    if (!(unicodestr = av_malloc_array(len, sizeof(*unicodestr)))) {
        goto out;
    }
    len = fribidi_charset_to_unicode(FRIBIDI_CHAR_SET_UTF8,
                                     *text, len, unicodestr);

    bidi_types = av_malloc_array(len, sizeof(*bidi_types));
    if (!bidi_types) {
        goto out;
    }

    fribidi_get_bidi_types(unicodestr, len, bidi_types);

    embedding_levels = av_malloc_array(len, sizeof(*embedding_levels));
    if (!embedding_levels) {
        goto out;
    }

    if (!fribidi_get_par_embedding_levels(bidi_types, len, &direction,
                                          embedding_levels)) {
        goto out;
    }

    ar_props = av_malloc_array(len, sizeof(*ar_props));
    if (!ar_props) {
        goto out;
    }

    fribidi_get_joining_types(unicodestr, len, ar_props);
    fribidi_join_arabic(bidi_types, len, embedding_levels, ar_props);
    fribidi_shape(flags, embedding_levels, len, ar_props, unicodestr);

    for (line_end = 0, line_start = 0; line_end < len; line_end++) {
        if (is_newline(unicodestr[line_end]) || line_end == len - 1) {
            if (!fribidi_reorder_line(flags, bidi_types,
                                      line_end - line_start + 1, line_start,
                                      direction, embedding_levels, unicodestr,
                                      NULL)) {
                goto out;
            }
            line_start = line_end + 1;
        }
    }

    /* Remove zero-width fill chars put in by libfribidi */
    for (i = 0, j = 0; i < len; i++)
        if (unicodestr[i] != FRIBIDI_CHAR_FILL)
            unicodestr[j++] = unicodestr[i];
    len = j;

    if (!(tmp = av_realloc(*text, (len * 4 + 1) * sizeof(char)))) {
        /* Use len * 4, as a unicode character can be up to 4 bytes in UTF-8 */
        goto out;
    }

    *text = tmp;
    len = fribidi_unicode_to_charset(FRIBIDI_CHAR_SET_UTF8,
                                     unicodestr, len, *text);
    ret = 0;

out:
    av_free(unicodestr);
    av_free(embedding_levels);
    av_free(ar_props);
    av_free(bidi_types);
    return ret;
}
#endif

static void parse_and_init_text(DrawPosterContext *s, char* textStr, char* posStr)
{
	char* p = textStr;
	while(*p) {
		if(*p == '|') {
			s->textNum++;
		}
		++p;
	}
	s->textNum += 1;
	s->textArr = av_mallocz(s->textNum*sizeof(char*));
	s->textPos = av_mallocz(s->textNum*sizeof(FT_Vector));
	
	p = textStr;
	char* curItem = NULL;
	int idx = 0;
	while(curItem = av_strtok(p, "|", &p)) {
		s->textArr[idx] = av_strdup(curItem);
		idx++;
	}

	p = posStr;
	idx = 0;
	while(curItem = av_strtok(p, "|,", &p)) {
		int posIdx = idx >> 1;
		if(idx%2 == 0) {
			s->textPos[posIdx].x = atoi(curItem);
		} else {
			s->textPos[posIdx].y = atoi(curItem);
		}
		idx++;
	}
	
	#if CONFIG_LIBFRIBIDI
	for(idx = 0; idx < s->textNum; ++idx) {
		if (s->text_shaping)
			if ((err = shape_text(&s->textArr[idx])) < 0)
				return err;
		
		av_log(ctx, AV_LOG_INFO, "Shaped text:%s.\n", s->textArr[idx]);
	}
	#endif
}

static int parse_and_init_picture(DrawPosterContext *s, char* picfileStr, char* picPosStr, char* picSizeStr)
{
	char* p = picfileStr;
	while(*p) {
		if(*p == '|') {
			s->picNum++;
		}
		++p;
	}
	s->picNum += 1;
	s->picArr = av_mallocz(s->picNum*sizeof(AVFrame*));
	s->picPos = av_mallocz(s->picNum*sizeof(FT_Vector));
	s->picSize = av_mallocz(s->picNum*sizeof(FT_Vector));
	
	char* curItem = NULL;
	p = picPosStr;
	int idx = 0;
	while(curItem = av_strtok(p, "|,", &p)) {
		int posIdx = idx >> 1;
		if(idx%2 == 0) {
			s->picPos[posIdx].x = atoi(curItem);
		} else {
			s->picPos[posIdx].y = atoi(curItem);
		}
		idx++;
	}
	
	if(picSizeStr) {
		p = picSizeStr;
		idx = 0;
		while(curItem = av_strtok(p, "|,", &p)) {
			int posIdx = idx >> 1;
			if(idx%2 == 0) {
				s->picSize[posIdx].x = atoi(curItem);
			} else {
				s->picSize[posIdx].y = atoi(curItem);
			}
			idx++;
		}
	}
	
	p = picfileStr;
	idx = 0;
	while(curItem = av_strtok(p, "|", &p)) {
		AVFrame* pFrame = av_frame_alloc();
		FT_Vector* pSize = &s->picSize[idx];
		if(pSize->x > 0 && pSize->y > 0) {
			pFrame->width = pSize->x;
			pFrame->height = pSize->y;
		}
		if(decode_picture(s, curItem, pFrame) != 0) {
			av_log(s, AV_LOG_ERROR, "Decode picture failed, %s.\n", curItem);
			return -1;
		}
		s->picArr[idx] = pFrame;
		idx++;
	}
	return 0;
}

static av_cold int init(AVFilterContext *ctx)
{
    int err;
    DrawPosterContext *s = ctx->priv;
	Glyph *glyph;

	if(!s->picfileStr && !s->textStr) {
		av_log(ctx, AV_LOG_ERROR, "Neither picture file nor texts provided.\n");
        return AVERROR(EINVAL);
	}
	
	s->renderFramesCounter = 0;
	
	if(s->picfileStr) {
		err = parse_and_init_picture(s, s->picfileStr, s->picPosStr, s->picSizeStr);
		if(err < 0) {
			return err;
		}
	}
	
	if(s->textStr) {
		if (!s->fontfile && !CONFIG_LIBFONTCONFIG) {
			av_log(ctx, AV_LOG_ERROR, "No font filename provided\n");
			return AVERROR(EINVAL);
		}
		
		if (!s->textStr || !s->textPosStr) {
			av_log(ctx, AV_LOG_ERROR,
				   "At least one text and text position must be provided.\n");
			return AVERROR(EINVAL);
		}
		
		// Parse text and text positions
		parse_and_init_text(s, s->textStr, s->textPosStr);
    
		if ((err = FT_Init_FreeType(&(s->library)))) {
			av_log(ctx, AV_LOG_ERROR,
				   "Could not load FreeType: %s\n", FT_ERRMSG(err));
			return AVERROR(EINVAL);
		}

		err = load_font(ctx);
		if (err) {
			av_log(ctx, AV_LOG_ERROR, "Could not load font.\n");
			return err;
		}
			
		if (!s->fontsize)
			s->fontsize = 16;
		if ((err = FT_Set_Pixel_Sizes(s->face, 0, s->fontsize))) {
			av_log(ctx, AV_LOG_ERROR, "Could not set font size to %d pixels: %s\n",
				   s->fontsize, FT_ERRMSG(err));
			return AVERROR(EINVAL);
		}

		if (s->borderw) {
			if (FT_Stroker_New(s->library, &s->stroker)) {
				av_log(ctx, AV_LOG_ERROR, "Coult not init FT stroker\n");
				return AVERROR_EXTERNAL;
			}
			FT_Stroker_Set(s->stroker, s->borderw << 6, FT_STROKER_LINECAP_ROUND,
						   FT_STROKER_LINEJOIN_ROUND, 0);
		}

		s->use_kerning = FT_HAS_KERNING(s->face);

		/* load the fallback glyph with code 0 */
		load_glyph(ctx, NULL, 0);

		/* set the tabsize in pixels */
		if ((err = load_glyph(ctx, &glyph, ' ')) < 0) {
			av_log(ctx, AV_LOG_ERROR, "Could not set tabsize.\n");
			return err;
		}
		s->tabsize *= glyph->advance;
	}
	
    return 0;
}

static int glyph_enu_free(void *opaque, void *elem)
{
    Glyph *glyph = elem;

    FT_Done_Glyph(glyph->glyph);
    FT_Done_Glyph(glyph->border_glyph);
    av_free(elem);
    return 0;
}

static av_cold void uninit(AVFilterContext *ctx)
{
    DrawPosterContext *s = ctx->priv;
	if(s->picfileStr) {
		int i = 0;
		for(; i<s->picNum; ++i) {
			av_frame_free(&s->picArr[i]);
		}
		av_freep(&s->picArr);
		av_freep(&s->picPos);
		av_freep(&s->picSize);
	}
	
	if(s->textStr) {
		av_freep(&s->chRelativePos);
		s->nb_chRelativePos = 0;
		
		av_freep(&s->textPos);
		int i = 0;
		for(; i<s->textNum; ++i) {
			av_free(s->textArr[i]);
		}
		av_freep(&s->textArr);
		
		av_tree_enumerate(s->glyphs, NULL, NULL, glyph_enu_free);
		av_tree_destroy(s->glyphs);
		s->glyphs = NULL;

		FT_Done_Face(s->face);
		FT_Stroker_Done(s->stroker);
		FT_Done_FreeType(s->library);
	}
}


static int config_input(AVFilterLink *inlink)
{
    AVFilterContext *ctx = inlink->dst;
    DrawPosterContext *s = ctx->priv;
	
	if(s->textStr) {
		ff_draw_init(&s->dc, inlink->format, 0);
		ff_draw_color(&s->dc, &s->fontcolor,   s->fontcolor.rgba);
		ff_draw_color(&s->dc, &s->shadowcolor, s->shadowcolor.rgba);
		ff_draw_color(&s->dc, &s->bordercolor, s->bordercolor.rgba);
		ff_draw_color(&s->dc, &s->boxcolor,    s->boxcolor.rgba);
	}
	
    return 0;
}


static int command(AVFilterContext *ctx, const char *cmd, const char *arg, char *res, int res_len, int flags)
{
    DrawPosterContext *s = ctx->priv;

    if (!strcmp(cmd, "changetext")) {	// arg format "0,Shanghai|1,Tianjing|2,Haikou"
        if(!arg || !*arg) {
			return AVERROR(EINVAL);
		}
		
		char* curItem = NULL;
		char* tmpStr = av_strdup(arg);
		char* p = tmpStr;
		int idx = 0;
		int curStrIdx = 0;
		while(curItem = av_strtok(p, "|,", &p)) {
			if(idx%2 == 0) {
				curStrIdx = atoi(curItem);
			} else {
				av_free(s->textArr[curStrIdx]);
				s->textArr[curStrIdx] = av_strdup(curItem);
			}
			idx++;
		}
		av_free(tmpStr);
		return 0;
	} else if(!strcmp(cmd, "resettext")) {
		av_freep(&s->textPos);
		int i = 0;
		for(; i<s->textNum; ++i) {
			av_free(s->textArr[i]);
		}
		av_freep(&s->textArr);
		s->textNum = 0;
		char* tmpStr = av_strdup(arg);
		char* p = tmpStr;
		char* curItem = av_strtok(p, ";", &p);
		parse_and_init_text(s, curItem, p);
		av_free(tmpStr);
	} else if(!strcmp(cmd, "resetframecounter")) {
		s->renderFramesCounter = atoi(arg);
	} else if(!strcmp(cmd, "changepic")) {	
		// arg format "0\,./logo1.png|1\,logo2.png;0\,40*80|1\,70*100"
		// use ';' split 2 part, front part to change picture, back part to change picture position
        if(!arg || !*arg) {
			return AVERROR(EINVAL);
		}
		
		char* curItem = NULL;
		const char* commaPos = strchr(arg, ';');
		char* picStr = NULL;
		char* posStr = NULL;
		if(commaPos) {
			picStr = av_strndup(arg, commaPos-arg);
			posStr = av_strdup(commaPos+1);
		} else {
			picStr = av_strdup(arg);
		}
		
		// Parse picture string
		char* p = picStr;
		int idx = 0;
		int curStrIdx = 0;
		while(curItem = av_strtok(p, "|,", &p)) {
			if(idx%2 == 0) {
				curStrIdx = atoi(curItem);
			} else {
				av_frame_free(&s->picArr[curStrIdx]);
				AVFrame* pFrame = av_frame_alloc();
				FT_Vector* pSize = &s->picSize[curStrIdx];
				pFrame->width = pSize->x;
				pFrame->height = pSize->y;
				if(decode_picture(s, curItem, pFrame) != 0) {
					return AVERROR(EINVAL);
				}
				s->picArr[curStrIdx] = pFrame;
			}
			idx++;
		}
		
		// Parse position string
		if(posStr) {
			p = posStr;
			idx = 0;
			curStrIdx = 0;
			while(curItem = av_strtok(p, "|,", &p)) {
				if(idx%2 == 0) {
					curStrIdx = atoi(curItem);
				} else {
					int x = atoi(curItem);
					char* starPos = strchr(curItem, '*');
					int y = atoi(starPos+1);
					s->picPos[curStrIdx].x = x;
					s->picPos[curStrIdx].y = y;
				}
				idx++;
			}
		}
		
		av_free(picStr);
		av_free(posStr);
		return 0;
	}
	
    return AVERROR(ENOSYS);
}

static int draw_pic(AVFilterContext *ctx, AVFrame *frame,
                     AVFrame* pic, int x, int y)
{
    //DrawPosterContext *s = ctx->priv;
	blend_image(frame, pic, x, y);
    return 0;
}

static int draw_glyphs(DrawPosterContext *s, AVFrame *frame,
					   char *text, FT_Vector* pos,
                       int width, int height,
                       FFDrawColor *color,
                       int x, int y, int borderw)
{
    uint32_t code = 0;
    int i, x1, y1;
    uint8_t *p;
    Glyph *glyph = NULL;
    
    for (i = 0, p = text; *p; i++) {
        FT_Bitmap bitmap;
        Glyph dummy = { 0 };
        GET_UTF8(code, *p++, continue;);

        /* skip new line chars, just go to new line */
        if (code == '\n' || code == '\r' || code == '\t')
            continue;

        dummy.code = code;
        glyph = av_tree_find(s->glyphs, &dummy, (void *)glyph_cmp, NULL);

        bitmap = borderw ? glyph->border_bitmap : glyph->bitmap;

        if (glyph->bitmap.pixel_mode != FT_PIXEL_MODE_MONO &&
            glyph->bitmap.pixel_mode != FT_PIXEL_MODE_GRAY)
            return AVERROR(EINVAL);

        x1 = s->chRelativePos[i].x+pos->x+x - borderw;
        y1 = s->chRelativePos[i].y+pos->y+y - borderw;

        ff_blend_mask(&s->dc, color,
                      frame->data, frame->linesize, width, height,
                      bitmap.buffer, bitmap.pitch,
                      bitmap.width, bitmap.rows,
                      bitmap.pixel_mode == FT_PIXEL_MODE_MONO ? 0 : 3,
                      0, x1, y1);
    }

    return 0;
}

static int draw_text(AVFilterContext *ctx, AVFrame *frame,
                     char *text, FT_Vector* pos, int width, int height)
{
    DrawPosterContext *s = ctx->priv;
    //AVFilterLink *inlink = ctx->inputs[0];
    uint32_t code = 0, prev_code = 0;
    int x = 0, y = 0, i = 0, ret;
    int max_text_line_w = 0, len;
    int box_w, box_h;
    
    uint8_t *p;
    int y_min = 32000, y_max = -32000;
    int x_min = 32000, x_max = -32000;
    FT_Vector delta;
    Glyph *glyph = NULL, *prev_glyph = NULL;
    Glyph dummy = { 0 };

    FFDrawColor fontcolor;
    FFDrawColor shadowcolor;
    FFDrawColor bordercolor;
    FFDrawColor boxcolor;
    x = 0;
    y = 0;

	if ((len = strlen(text)) > s->nb_chRelativePos) {
        if (!(s->chRelativePos =
              av_realloc(s->chRelativePos, len*sizeof(*s->chRelativePos))))
            return AVERROR(ENOMEM);
        s->nb_chRelativePos = len;
    }
	
    /* load and cache glyphs */
    for (i = 0, p = text; *p; i++) {
        GET_UTF8(code, *p++, continue;);
		
        /* get glyph */
        dummy.code = code;
        glyph = av_tree_find(s->glyphs, &dummy, glyph_cmp, NULL);
        if (!glyph) {
            load_glyph(ctx, &glyph, code);
        }

        y_min = FFMIN(glyph->bbox.yMin, y_min);
        y_max = FFMAX(glyph->bbox.yMax, y_max);
        x_min = FFMIN(glyph->bbox.xMin, x_min);
        x_max = FFMAX(glyph->bbox.xMax, x_max);
    }
    s->max_glyph_h = y_max - y_min;
    s->max_glyph_w = x_max - x_min;

    /* compute and save position for each glyph */
    glyph = NULL;
    for (i = 0, p = text; *p; i++) {
        GET_UTF8(code, *p++, continue;);

        /* skip the \n in the sequence \r\n */
        if (prev_code == '\r' && code == '\n')
            continue;

        prev_code = code;
        if (is_newline(code)) {

            max_text_line_w = FFMAX(max_text_line_w, x);
            y += s->max_glyph_h;
            x = 0;
            continue;
        }

        /* get glyph */
        prev_glyph = glyph;
        dummy.code = code;
        glyph = av_tree_find(s->glyphs, &dummy, glyph_cmp, NULL);

        /* kerning */
        if (s->use_kerning && prev_glyph && glyph->code) {
            FT_Get_Kerning(s->face, prev_glyph->code, glyph->code,
                           ft_kerning_default, &delta);
            x += delta.x >> 6;
        }

        /* save position */
        s->chRelativePos[i].x = x + glyph->bitmap_left;
        s->chRelativePos[i].y = y - glyph->bitmap_top + y_max;
        if (code == '\t') x  = (x / s->tabsize + 1)*s->tabsize;
        else              x += glyph->advance;
    }

    max_text_line_w = FFMAX(x, max_text_line_w);

    update_color_with_alpha(s, &fontcolor  , s->fontcolor  );
    update_color_with_alpha(s, &shadowcolor, s->shadowcolor);
    update_color_with_alpha(s, &bordercolor, s->bordercolor);
    update_color_with_alpha(s, &boxcolor   , s->boxcolor   );

    box_w = FFMIN(width - 1 , max_text_line_w);
    box_h = FFMIN(height - 1, y + s->max_glyph_h);

    /* draw box */
    if (s->draw_box)
        ff_blend_rectangle(&s->dc, &boxcolor,
                           frame->data, frame->linesize, width, height,
                           pos->x - s->boxborderw, pos->y - s->boxborderw,
                           box_w + s->boxborderw * 2, box_h + s->boxborderw * 2);
	
    if (s->shadowx || s->shadowy) {
        if ((ret = draw_glyphs(s, frame, text, pos, width, height,
                               &shadowcolor, s->shadowx, s->shadowy, 0)) < 0)
            return ret;
    }
    
    if (s->borderw) {
        if ((ret = draw_glyphs(s, frame, text, pos, width, height,
                               &bordercolor, 0, 0, s->borderw)) < 0)
            return ret;
    }
	
    if ((ret = draw_glyphs(s, frame, text, pos, width, height,
                           &fontcolor, 0, 0, 0)) < 0)
        return ret;
    
    return 0;
}

static int filter_frame(AVFilterLink *inlink, AVFrame *frame)
{
    AVFilterContext *ctx = inlink->dst;
    AVFilterLink *outlink = ctx->outputs[0];
    DrawPosterContext *s = ctx->priv;
	
	if(s->frames > 0) {
		s->renderFramesCounter++;
		if(s->renderFramesCounter > s->frames) {
			return ff_filter_frame(outlink, frame);
		}
	}
	
	if(s->picfileStr) {
		int i = 0;
		for(; i<s->picNum; ++i) {
			AVFrame* pPic = s->picArr[i];
			FT_Vector* pos = &(s->picPos[i]);
			draw_pic(ctx, frame, pPic, pos->x, pos->y);
		}
	}
	
    if(s->textStr) {
		int i = 0;
		for(; i<s->textNum; ++i) {
			char* text=s->textArr[i];
			FT_Vector* pos = &(s->textPos[i]);
			draw_text(ctx, frame, text, pos, frame->width, frame->height);
		}
	}
	
    return ff_filter_frame(outlink, frame);
}

static const AVFilterPad avfilter_vf_drawposter_inputs[] = {
    {
        .name           = "default",
        .type           = AVMEDIA_TYPE_VIDEO,
        .filter_frame   = filter_frame,
        .config_props   = config_input,
        .needs_writable = 1,
    },
    { NULL }
};

static const AVFilterPad avfilter_vf_drawposter_outputs[] = {
    {
        .name = "default",
        .type = AVMEDIA_TYPE_VIDEO,
    },
    { NULL }
};

AVFilter ff_vf_drawposter = {
    .name          = "drawposter",
    .description   = NULL_IF_CONFIG_SMALL("Draw pictiure and text on top of video frames."),
    .priv_size     = sizeof(DrawPosterContext),
    .priv_class    = &drawposter_class,
    .init          = init,
    .uninit        = uninit,
    .query_formats = query_formats,
    .inputs        = avfilter_vf_drawposter_inputs,
    .outputs       = avfilter_vf_drawposter_outputs,
    .process_command = command,
    .flags         = AVFILTER_FLAG_SUPPORT_TIMELINE_GENERIC,
};

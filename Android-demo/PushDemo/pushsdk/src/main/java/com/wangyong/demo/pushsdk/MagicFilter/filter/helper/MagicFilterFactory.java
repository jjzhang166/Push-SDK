package com.wangyong.demo.pushsdk.MagicFilter.filter.helper;

import com.wangyong.demo.pushsdk.MagicFilter.filter.advanced.MagicAmaroFilter;
import com.wangyong.demo.pushsdk.MagicFilter.filter.advanced.MagicAntiqueFilter;
import com.wangyong.demo.pushsdk.MagicFilter.filter.advanced.MagicBlackCatFilter;
import com.wangyong.demo.pushsdk.MagicFilter.filter.advanced.MagicBrannanFilter;
import com.wangyong.demo.pushsdk.MagicFilter.filter.advanced.MagicBrooklynFilter;
import com.wangyong.demo.pushsdk.MagicFilter.filter.advanced.MagicCalmFilter;
import com.wangyong.demo.pushsdk.MagicFilter.filter.advanced.MagicCoolFilter;
import com.wangyong.demo.pushsdk.MagicFilter.filter.advanced.MagicCrayonFilter;
import com.wangyong.demo.pushsdk.MagicFilter.filter.advanced.MagicEarlyBirdFilter;
import com.wangyong.demo.pushsdk.MagicFilter.filter.advanced.MagicEmeraldFilter;
import com.wangyong.demo.pushsdk.MagicFilter.filter.advanced.MagicEvergreenFilter;
import com.wangyong.demo.pushsdk.MagicFilter.filter.advanced.MagicFairytaleFilter;
import com.wangyong.demo.pushsdk.MagicFilter.filter.advanced.MagicFreudFilter;
import com.wangyong.demo.pushsdk.MagicFilter.filter.advanced.MagicHealthyFilter;
import com.wangyong.demo.pushsdk.MagicFilter.filter.advanced.MagicHefeFilter;
import com.wangyong.demo.pushsdk.MagicFilter.filter.advanced.MagicHudsonFilter;
import com.wangyong.demo.pushsdk.MagicFilter.filter.advanced.MagicImageAdjustFilter;
import com.wangyong.demo.pushsdk.MagicFilter.filter.advanced.MagicInkwellFilter;
import com.wangyong.demo.pushsdk.MagicFilter.filter.advanced.MagicKevinFilter;
import com.wangyong.demo.pushsdk.MagicFilter.filter.advanced.MagicLatteFilter;
import com.wangyong.demo.pushsdk.MagicFilter.filter.advanced.MagicLomoFilter;
import com.wangyong.demo.pushsdk.MagicFilter.filter.advanced.MagicN1977Filter;
import com.wangyong.demo.pushsdk.MagicFilter.filter.advanced.MagicNashvilleFilter;
import com.wangyong.demo.pushsdk.MagicFilter.filter.advanced.MagicNostalgiaFilter;
import com.wangyong.demo.pushsdk.MagicFilter.filter.advanced.MagicPixarFilter;
import com.wangyong.demo.pushsdk.MagicFilter.filter.advanced.MagicRiseFilter;
import com.wangyong.demo.pushsdk.MagicFilter.filter.advanced.MagicRomanceFilter;
import com.wangyong.demo.pushsdk.MagicFilter.filter.advanced.MagicSakuraFilter;
import com.wangyong.demo.pushsdk.MagicFilter.filter.advanced.MagicSierraFilter;
import com.wangyong.demo.pushsdk.MagicFilter.filter.advanced.MagicSketchFilter;
import com.wangyong.demo.pushsdk.MagicFilter.filter.advanced.MagicSkinWhitenFilter;
import com.wangyong.demo.pushsdk.MagicFilter.filter.advanced.MagicSunriseFilter;
import com.wangyong.demo.pushsdk.MagicFilter.filter.advanced.MagicSunsetFilter;
import com.wangyong.demo.pushsdk.MagicFilter.filter.advanced.MagicSutroFilter;
import com.wangyong.demo.pushsdk.MagicFilter.filter.advanced.MagicSweetsFilter;
import com.wangyong.demo.pushsdk.MagicFilter.filter.advanced.MagicTenderFilter;
import com.wangyong.demo.pushsdk.MagicFilter.filter.advanced.MagicToasterFilter;
import com.wangyong.demo.pushsdk.MagicFilter.filter.advanced.MagicValenciaFilter;
import com.wangyong.demo.pushsdk.MagicFilter.filter.advanced.MagicWaldenFilter;
import com.wangyong.demo.pushsdk.MagicFilter.filter.advanced.MagicWarmFilter;
import com.wangyong.demo.pushsdk.MagicFilter.filter.advanced.MagicWhiteCatFilter;
import com.wangyong.demo.pushsdk.MagicFilter.filter.advanced.MagicXproIIFilter;
import com.wangyong.demo.pushsdk.MagicFilter.filter.base.gpuimage.GPUImageBrightnessFilter;
import com.wangyong.demo.pushsdk.MagicFilter.filter.base.gpuimage.GPUImageContrastFilter;
import com.wangyong.demo.pushsdk.MagicFilter.filter.base.gpuimage.GPUImageExposureFilter;
import com.wangyong.demo.pushsdk.MagicFilter.filter.base.gpuimage.GPUImageFilter;
import com.wangyong.demo.pushsdk.MagicFilter.filter.base.gpuimage.GPUImageHueFilter;
import com.wangyong.demo.pushsdk.MagicFilter.filter.base.gpuimage.GPUImageSaturationFilter;
import com.wangyong.demo.pushsdk.MagicFilter.filter.base.gpuimage.GPUImageSharpenFilter;

public class MagicFilterFactory{
	
	private static MagicFilterType filterType = MagicFilterType.NONE;
	
	public static GPUImageFilter initFilters(MagicFilterType type){
		filterType = type;
		switch (type) {
		case WHITECAT:
			return new MagicWhiteCatFilter();
		case BLACKCAT:
			return new MagicBlackCatFilter();
		case SKINWHITEN:
			return new MagicSkinWhitenFilter();
		case ROMANCE:
			return new MagicRomanceFilter();
		case SAKURA:
			return new MagicSakuraFilter();
		case AMARO:
			return new MagicAmaroFilter();
		case WALDEN:
			return new MagicWaldenFilter();
		case ANTIQUE:
			return new MagicAntiqueFilter();
		case CALM:
			return new MagicCalmFilter();
		case BRANNAN:
			return new MagicBrannanFilter();
		case BROOKLYN:
			return new MagicBrooklynFilter();
		case EARLYBIRD:
			return new MagicEarlyBirdFilter();
		case FREUD:
			return new MagicFreudFilter();
		case HEFE:
			return new MagicHefeFilter();
		case HUDSON:
			return new MagicHudsonFilter();
		case INKWELL:
			return new MagicInkwellFilter();
		case KEVIN:
			return new MagicKevinFilter();
		case LOMO:
			return new MagicLomoFilter();
		case N1977:
			return new MagicN1977Filter();
		case NASHVILLE:
			return new MagicNashvilleFilter();
		case PIXAR:
			return new MagicPixarFilter();
		case RISE:
			return new MagicRiseFilter();
		case SIERRA:
			return new MagicSierraFilter();
		case SUTRO:
			return new MagicSutroFilter();
		case TOASTER2:
			return new MagicToasterFilter();
		case VALENCIA:
			return new MagicValenciaFilter();
		case XPROII:
			return new MagicXproIIFilter();
		case EVERGREEN:
			return new MagicEvergreenFilter();
		case HEALTHY:
			return new MagicHealthyFilter();
		case COOL:
			return new MagicCoolFilter();
		case EMERALD:
			return new MagicEmeraldFilter();
		case LATTE:
			return new MagicLatteFilter();
		case WARM:
			return new MagicWarmFilter();
		case TENDER:
			return new MagicTenderFilter();
		case SWEETS:
			return new MagicSweetsFilter();
		case NOSTALGIA:
			return new MagicNostalgiaFilter();
		case FAIRYTALE:
			return new MagicFairytaleFilter();
		case SUNRISE:
			return new MagicSunriseFilter();
		case SUNSET:
			return new MagicSunsetFilter();
		case CRAYON:
			return new MagicCrayonFilter();
		case SKETCH:
			return new MagicSketchFilter();
		//image adjust
		case BRIGHTNESS:
			return new GPUImageBrightnessFilter();
		case CONTRAST:
			return new GPUImageContrastFilter();
		case EXPOSURE:
			return new GPUImageExposureFilter();
		case HUE:
			return new GPUImageHueFilter();
		case SATURATION:
			return new GPUImageSaturationFilter();
		case SHARPEN:
			return new GPUImageSharpenFilter();
		case IMAGE_ADJUST:
			return new MagicImageAdjustFilter();
		default:
			return null;
		}
	}
	
	public MagicFilterType getCurrentFilterType(){
		return filterType;
	}
}

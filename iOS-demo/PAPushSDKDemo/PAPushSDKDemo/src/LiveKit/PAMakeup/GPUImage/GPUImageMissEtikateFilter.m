#import "GPUImageMissEtikateFilter.h"
#import "GPUImagePicture.h"
#import "GPUImageLookupFilter.h"



@implementation GPUImageMissEtikateFilter

- (id)initWithImage:(NSString*)im
{
    if (!(self = [super init]))
    {
		return nil;
    }
    
    self.imageName = im;

    UIImage *image = [UIImage imageNamed:im];
    lookupImageSource = [[GPUImagePicture alloc] initWithImage:image];
    GPUImageLookupFilter *lookupFilter = [[GPUImageLookupFilter alloc] init];
    [self addFilter:lookupFilter];

    [lookupImageSource addTarget:lookupFilter atTextureLocation:1];
    [lookupImageSource processImage];

    self.initialFilters = [NSArray arrayWithObjects:lookupFilter, nil];
    self.terminalFilter = lookupFilter;

    return self;
}


#pragma mark -
#pragma mark Accessors

@end

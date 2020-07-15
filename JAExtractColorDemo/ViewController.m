//
//  ViewController.m
//  JAExtractColorDemo
//
//  Created by Jater on 2020/7/15.
//

#import "ViewController.h"

@interface ViewController ()

@property (weak, nonatomic) IBOutlet UIImageView *imageview;
@property (weak, nonatomic) IBOutlet UIView *colorView;
@property (weak, nonatomic) IBOutlet UIView *ScanBox;
@property (weak, nonatomic) IBOutlet UIImageView *cropImageView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.imageview.contentMode = UIViewContentModeScaleAspectFit;
    self.cropImageView.contentMode = UIViewContentModeScaleAspectFill;
    
    self.ScanBox.backgroundColor = UIColor.clearColor;
    self.ScanBox.layer.borderWidth = 1;
    self.ScanBox.layer.borderColor = UIColor.orangeColor.CGColor;
    UIPanGestureRecognizer *pgr = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(move:)];
    pgr.maximumNumberOfTouches = 1;
    [self.ScanBox addGestureRecognizer:pgr];
}

- (UIImage *)makeImageWithView:(UIView *)view coverRect:(CGRect)coverRect{
    CGFloat scale = [UIScreen mainScreen].scale;
    UIGraphicsBeginImageContextWithOptions(view.bounds.size, YES, scale);
    [view.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    // 按比例扩大剪切区域
    CGRect tempRect = CGRectMake(CGRectGetMinX(coverRect) * scale, CGRectGetMinY(coverRect) * scale, CGRectGetWidth(coverRect) * scale, CGRectGetHeight(coverRect) * scale );
    //将UIImage转换成CGImageRef
    CGImageRef sourceImageRef = [image CGImage];
    //按照给定的矩形区域进行剪裁
    CGImageRef newImageRef = CGImageCreateWithImageInRect(sourceImageRef, tempRect);
    //将CGImageRef转换成UIImage
    image = [UIImage imageWithCGImage:newImageRef];

    return image;
}

- (void)move:(UIGestureRecognizer *)gr {
    CGPoint point = [gr locationInView:self.view];
    self.ScanBox.center = point;
    if (gr.state == UIGestureRecognizerStateEnded) {
        UIImage *theImage = [self makeImageWithView:self.imageview coverRect:self.ScanBox.frame];
        self.cropImageView.image = theImage;
        UIColor *color = [self extracyColorWithImage:theImage];
        self.colorView.backgroundColor = color;
    }
}

- (UIColor *)extracyColorWithImage:(UIImage *)image {
    NSMutableArray *array = [NSMutableArray new];
    CGSize imageSize = image.size;
    CGContextRef context = [self ARGBContextWithSize:imageSize];
    unsigned char* cArray = [self rawBitmapDataForImage:image inContext:context];

    NSInteger numberOfPixels = (NSInteger) imageSize.width * imageSize.height;
    UIColor *color;
    for (int i = 0; i < numberOfPixels * 4; i += 4) {
        color = [UIColor colorWithRed:cArray[i+1]/255.f
                                green:cArray[i+2]/255.f
                                 blue:cArray[i+3]/255.f
                                alpha:cArray[i]/255.f];
        [array addObject:color];
    }

    CGContextRelease(context);
    return [self meanColorWithColors:array];
}

- (unsigned char *)rawBitmapDataForImage:(UIImage *)image inContext:(CGContextRef)context {
    CGRect rect = CGRectMake(0, 0, image.size.width, image.size.height);
    CGContextDrawImage(context, rect, image.CGImage);
    unsigned char *data = CGBitmapContextGetData(context);
    return data;
}

- (CGContextRef)ARGBContextWithSize:(CGSize)size {
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    if (!colorSpace) {
        [NSException raise:NSInternalInconsistencyException format:@"Error creating color space."];
    }
    CGBitmapInfo alphaSettings = (CGBitmapInfo) kCGImageAlphaPremultipliedFirst;
    CGContextRef contextRef = CGBitmapContextCreate(NULL, size.width, size.height, 8,
                                                    0, colorSpace, alphaSettings);
    if (!contextRef) {
        [NSException raise:NSInternalInconsistencyException format:@"Error creating context."];
    }

    CGColorSpaceRelease(colorSpace);
    return contextRef;
}

- (UIColor *)meanColorWithColors:(NSArray *)colors {
    NSInteger colorCount = [colors count];
    if (colorCount == 0) {
        return nil;
    }
    CGFloat total_r = 0.f, total_g = 0.f, total_b = 0.f;
    CGFloat color_r, color_g, color_b;
    for (UIColor *color in colors) {
        [color getRed:&color_r green:&color_g blue:&color_b alpha:NULL];
        total_r += color_r;
        total_g += color_g;
        total_b += color_b;
    }
    return [UIColor colorWithRed:total_r / colorCount
                           green:total_g / colorCount
                            blue:total_b / colorCount
                           alpha:1.0f];
}

@end

//
//  AppDelegate.m
//  佛爱我羊
//
//  Created by AK on 16/3/18.
//  Copyright © 2016年 ak. All rights reserved.
//

#import "AppDelegate.h"

#define KEY_SAVE_PDFPATH @"KEY_SAVE_PDFPATH"
#define KEY_SAVE_TAGPATH @"KEY_SAVE_TAGPATH"

@interface AppDelegate ()

@property(weak) IBOutlet NSWindow *window;
@property(weak) IBOutlet NSTextField *pdfPath;
@property(weak) IBOutlet NSTextField *tagPath;
@property(weak) IBOutlet NSButton *selectPDFBtn;
@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    //固定窗口大小
    [self.window setStyleMask:NSTitledWindowMask | NSMiniaturizableWindowMask | NSClosableWindowMask];

    NSUserDefaults *userDefaultes = [NSUserDefaults standardUserDefaults];

    if ([userDefaultes objectForKey:KEY_SAVE_PDFPATH])
    {
        self.pdfPath.stringValue = [userDefaultes objectForKey:KEY_SAVE_PDFPATH];
    }
    if ([userDefaultes objectForKey:KEY_SAVE_TAGPATH])
    {
        self.tagPath.stringValue = [userDefaultes objectForKey:KEY_SAVE_TAGPATH];
    }
}

- (void)applicationWillTerminate:(NSNotification *)aNotification
{
    // Insert code here to tear down your application
}

- (IBAction)pdfPathOnclick:(id)sender
{
    NSOpenPanel *panel = [NSOpenPanel openPanel];
    [panel setMessage:@"Please select a source folder."];
    [panel setCanChooseDirectories:YES];
    [panel setCanCreateDirectories:YES];

    [panel setCanChooseFiles:NO];

    [panel beginSheetModalForWindow:[NSApp mainWindow]
                  completionHandler:^(NSInteger result) {

                      if (result == NSFileHandlingPanelOKButton)
                      {
                          NSURL *url = [panel URL];

                          NSLog(@"you select %@", url);

                          self.pdfPath.stringValue = [url path];
                      }

                  }];
}

- (IBAction)createFile:(id)sender
{
    if (self.pdfPath.stringValue.length > 0 && self.tagPath.stringValue.length > 0)
    {
        NSUserDefaults *userDefaultes = [NSUserDefaults standardUserDefaults];
        [userDefaultes setObject:self.pdfPath.stringValue forKey:KEY_SAVE_PDFPATH];
        [userDefaultes setObject:self.tagPath.stringValue forKey:KEY_SAVE_TAGPATH];
        [userDefaultes synchronize];

        NSLog(@"all pdf files %@", [self allFilesAtPath:self.pdfPath.stringValue]);

        for (NSString *str in [self allFilesAtPath:self.pdfPath.stringValue])
        {
            NSArray *data = [str componentsSeparatedByString:@"/"];

            //路径名 用于创建 xcassets目录 存放 .imageset目录
            NSString *finderName = [data objectAtIndex:0];

            //文件名 用于创建 .imageset目录 存放PDF等文件
            NSString *imagesetName = [data objectAtIndex:1];

            // 1,创建 xcassets目录
            NSFileManager *fileManager = [NSFileManager defaultManager];
            NSString *xcassetsPath = [self.tagPath.stringValue
                stringByAppendingPathComponent:[finderName stringByAppendingString:@".xcassets"]];
            if (![fileManager fileExistsAtPath:xcassetsPath])
            {
                [fileManager createDirectoryAtPath:xcassetsPath
                       withIntermediateDirectories:NO
                                        attributes:nil
                                             error:nil];
            }

            // 2,写入 xcassets json 配置文件

            /*
             {
             "info": {
             "version":1,
             "author":"xcode"
             }
             }
             */
            NSError *error;
            [[self dictionaryToJson:@{
                @"info" : @{@"version" : @"1", @"author" : @"xcode"}
            }] writeToFile:[xcassetsPath stringByAppendingPathComponent:@"Contents.json"]
                 atomically:YES
                   encoding:NSUTF8StringEncoding
                      error:&error];

            // 3,创建 .imageset目录
            if ([imagesetName hasSuffix:@".pdf"])
            {
                NSString *imagesetPath =

                    [xcassetsPath
                        stringByAppendingPathComponent:[[imagesetName
                                                           substringWithRange:NSMakeRange(0, imagesetName.length - 4)]
                                                           stringByAppendingString:@".imageset"]];

                if (![fileManager fileExistsAtPath:imagesetPath])
                {
                    [fileManager createDirectoryAtPath:imagesetPath
                           withIntermediateDirectories:NO
                                            attributes:nil
                                                 error:nil];
                }

                // 4,写入 imageset json 配置文件
                /*
                    {
                        "images": [
                            {
                             "idiom": "universal",
                             "filename": "unchecked.pdf"
                            }
                        ],
                        "info": {
                            "version": 1,
                            "author": "xcode"
                        },
                        "properties": {
                        "template-rendering-intent": "template"
                        }
                    }
                 */
                [[self dictionaryToJson:@{
                    @"images" : @[ @{@"idiom" : @"universal", @"filename" : imagesetName} ],
                    @"info" : @{@"version" : @1, @"author" : @"xcode"},
                    @"properties" : @{@"template-rendering-intent" : @"template"}
                }] writeToFile:[imagesetPath stringByAppendingPathComponent:@"Contents.json"]
                     atomically:YES
                       encoding:NSUTF8StringEncoding
                          error:&error];

                // 5,copy pdf to taget finder
                NSString *copyToPath = [imagesetPath stringByAppendingPathComponent:imagesetName];
                if ([self isExistAtPath:copyToPath])
                {
                    [fileManager removeItemAtPath:copyToPath error:nil];
                }
                [fileManager copyItemAtPath:[self.pdfPath.stringValue stringByAppendingPathComponent:str]
                                     toPath:copyToPath
                                      error:&error];

                if (error)
                {
                    NSLog(@"%@", [error localizedDescription]);
                }
            }
            else
            {
                NSLog(@"pdf file error");
            }
        }

        //完成提示
        NSAlert *alertDefult = [[NSAlert alloc] init];
        [alertDefult setMessageText:@"处理完成"];
        [alertDefult addButtonWithTitle:@"ok!"];
        [alertDefult runModal];
    }
    else
    {
        //错误提示
        NSAlert *alertDefult = [[NSAlert alloc] init];
        [alertDefult setMessageText:@"路径设置不对"];
        [alertDefult setInformativeText:@""];
        [alertDefult addButtonWithTitle:@"ok!"];
        [alertDefult runModal];
    }
}

- (IBAction)tagPathSelect:(id)sender
{
    NSOpenPanel *panel = [NSOpenPanel openPanel];
    [panel setMessage:@"Please select a source folder."];
    [panel setCanChooseDirectories:YES];
    [panel setCanCreateDirectories:YES];

    [panel setCanChooseFiles:NO];

    [panel beginSheetModalForWindow:[NSApp mainWindow]
                  completionHandler:^(NSInteger result) {

                      if (result == NSFileHandlingPanelOKButton)
                      {
                          NSURL *url = [panel URL];

                          self.tagPath.stringValue = [url path];
                      }

                  }];
}

//查出所有.pdf 文件
- (NSMutableArray *)allFilesAtPath:(NSString *)direString
{
    NSMutableArray *mutableFileURLs = [NSMutableArray array];
    NSFileManager *fm = [NSFileManager defaultManager];
    NSDirectoryEnumerator *dirEnum = [fm enumeratorAtPath:direString];

    while ((direString = [dirEnum nextObject]) != nil)
    {
        if ([direString hasSuffix:@".pdf"])
        {
            [mutableFileURLs addObject:direString];
        }
    }

    return mutableFileURLs;
}

// dic covert to string
- (NSString *)dictionaryToJson:(NSDictionary *)dic
{
    NSError *parseError = nil;
    NSData *jsonData =
        [NSJSONSerialization dataWithJSONObject:dic options:NSJSONWritingPrettyPrinted error:&parseError];
    return [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
}

//判断文件是否存在
- (BOOL)isExistAtPath:(NSString *)filePath
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL isExist = [fileManager fileExistsAtPath:filePath];
    return isExist;
}

- (void)setApplcationIcon
{
    NSString *strBundlePath = [[NSBundle mainBundle] bundlePath];

    //获取目录

    NSString *strBundleDir = [strBundlePath stringByDeletingLastPathComponent];

    //合成图标资源的全路径

    NSString *strIconPath = [strBundleDir stringByAppendingPathComponent:@"icon.jpg"];

    //读取图标文件

    NSImage *myAppIcon = [[NSImage alloc] initWithContentsOfFile:strIconPath];

    //得到当前的主程序

    NSApplication *currentApp = [NSApplication sharedApplication];

    //设置程序图标

    [currentApp setApplicationIconImage:myAppIcon];
}

@end

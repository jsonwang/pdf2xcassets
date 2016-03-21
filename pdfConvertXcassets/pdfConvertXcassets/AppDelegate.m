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
{
    NSFileManager *fileManager;
}

@property(weak) IBOutlet NSWindow *window;
@property(weak) IBOutlet NSTextField *pdfPath;
@property(weak) IBOutlet NSTextField *tagPath;
@property(weak) IBOutlet NSButton *selectPDFBtn;
@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    fileManager = [NSFileManager defaultManager];

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

- (void)createDirectoryWithPath:(NSString *)xcassetsPath
{
    NSLog(@"create dir %@", xcassetsPath);
    // 1,创建 xcassets目录
    NSError *error = nil;
    if (![fileManager fileExistsAtPath:xcassetsPath])
    {
        [fileManager createDirectoryAtPath:xcassetsPath withIntermediateDirectories:NO attributes:nil error:nil];
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

    [[self dictionaryToJson:@{
        @"info" : @{@"version" : @"1", @"author" : @"xcode"}
    }] writeToFile:[xcassetsPath stringByAppendingPathComponent:@"Contents.json"]
         atomically:YES
           encoding:NSUTF8StringEncoding
              error:&error];

    if (error)
    {
        NSLog(@"创建目录失败: %@", error);
    }
}

- (void)createPDFWithPath:(NSString *)path pdfName:(NSString *)pdfName pdfOldPath:(NSString *)pdfOldPath
{
    NSError *error = nil;

    // 3,创建 .imageset目录
    if ([pdfName hasSuffix:@".pdf"])
    {
        if (![fileManager fileExistsAtPath:[self.tagPath.stringValue stringByAppendingPathComponent:path]])
        {
            [fileManager createDirectoryAtPath:[self.tagPath.stringValue stringByAppendingPathComponent:path]
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
            @"images" : @[ @{@"idiom" : @"universal", @"filename" : pdfName} ],
            @"info" : @{@"version" : @1, @"author" : @"xcode"},
            @"properties" : @{@"template-rendering-intent" : @"template"}
        }] writeToFile:[[self.tagPath.stringValue stringByAppendingPathComponent:path]
                           stringByAppendingPathComponent:@"Contents.json"]
             atomically:YES
               encoding:NSUTF8StringEncoding
                  error:&error];

        // 5,copy pdf to taget finder
        NSString *copyToPath =
            [[self.tagPath.stringValue stringByAppendingPathComponent:path] stringByAppendingPathComponent:pdfName];
        if ([self isExistAtPath:copyToPath])
        {
            [fileManager removeItemAtPath:copyToPath error:nil];
        }

        [fileManager copyItemAtPath:[[self.pdfPath.stringValue stringByAppendingPathComponent:pdfOldPath]
                                        stringByAppendingPathComponent:pdfName]
                             toPath:copyToPath
                              error:&error];

        if (error)
        {
            NSLog(@"cp pdf file error: %@", [error localizedDescription]);
        }
    }

    else
    {
        NSLog(@"pdf file error");
    }
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

        /*

         "sample/stats/charts.pdf",
         "sample/tasks/checked.pdf",
         "sample/tasks/unchecked.pdf"

         */

        for (NSString *str in [self allFilesAtPath:self.pdfPath.stringValue])
        {
            NSArray *data = [str componentsSeparatedByString:@"/"];

            //路径名 用于创建 xcassets目录 存放 .imageset 就是目录
            NSString *directoryName = @"";

            NSString *pdfOldPath = @"";

            for (int i = 0; i < data.count; i++)
            {
                NSString *path = [data objectAtIndex:i];
                //是目录 要创建目录

                if (![path hasSuffix:@".pdf"])
                {
                    directoryName =
                        [directoryName stringByAppendingPathComponent:[path stringByAppendingString:@".xcassets"]];

                    pdfOldPath = [pdfOldPath stringByAppendingPathComponent:path];

                    NSString *xcassetsPath = [self.tagPath.stringValue stringByAppendingPathComponent:directoryName];
                    [self createDirectoryWithPath:xcassetsPath];
                }
                else
                {
                    NSString *imagesetPath =

                        [directoryName
                            stringByAppendingPathComponent:[[[data objectAtIndex:i]
                                                               substringWithRange:NSMakeRange(0, ((NSString *)[data
                                                                                                      objectAtIndex:i])
                                                                                                         .length -
                                                                                                     4)]
                                                               stringByAppendingString:@".imageset"]];
                    [self createPDFWithPath:imagesetPath pdfName:[data objectAtIndex:i] pdfOldPath:pdfOldPath];

                    directoryName = @"";
                    pdfOldPath = @"";
                }
            }
        }

        //完成提示
        NSAlert *alertDefult = [[NSAlert alloc] init];
        [alertDefult setMessageText:@"导出完成"];
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
    fileManager = [NSFileManager defaultManager];
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

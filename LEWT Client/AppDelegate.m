#import "AppDelegate.h"
#import "TouchBar.h"
#import <Foundation/Foundation.h>

static const NSTouchBarItemIdentifier kEnglishTextIdentifier = @"io.a2.EnglishText";
static const NSTouchBarItemIdentifier kEnglishSwitcherIdentifier = @"io.a2.EnglishSwitcher";
static const NSTouchBarItemIdentifier kGroupIdentifier = @"io.a2.Group";

@interface AppDelegate () <NSTouchBarDelegate>

@property (weak) IBOutlet NSWindow *window;
@property (nonatomic) NSTouchBar *groupTouchBar;

@end

@implementation AppDelegate {
    NSTimer *_textUpdateTimer; // Ссылка на таймер
}

- (NSTouchBar *)groupTouchBar
{
    if (!_groupTouchBar) {
        NSTouchBar *groupTouchBar = [[NSTouchBar alloc] init];
        groupTouchBar.defaultItemIdentifiers = @[ kEnglishTextIdentifier ];
        groupTouchBar.delegate = self;
        _groupTouchBar = groupTouchBar;
    }

    return _groupTouchBar;
}

- (void)present:(id)sender {
    if (@available(macOS 10.12.2, *)) {
        if ([NSTouchBar class]) {
            if (@available(macOS 10.14, *)) {
                [NSTouchBar presentSystemModalTouchBar:self.groupTouchBar systemTrayItemIdentifier:kEnglishSwitcherIdentifier];
            } else {
                [NSTouchBar presentSystemModalFunctionBar:self.groupTouchBar systemTrayItemIdentifier:kEnglishSwitcherIdentifier];
            }
        }
    }
}

- (NSTouchBarItem *)touchBar:(NSTouchBar *)touchBar
       makeItemForIdentifier:(NSTouchBarItemIdentifier)identifier {
    if ([identifier isEqualToString:kEnglishTextIdentifier]) {
        NSCustomTouchBarItem *bear =
            [[NSCustomTouchBarItem alloc] initWithIdentifier:kEnglishTextIdentifier];
        //bear.view = [NSButton buttonWithTitle:@"\U0001F43B" target:self action:@selector(bear:)];
        NSString *text = @"\u270F\uFE0F:";
        bear.view = [NSTextField labelWithString:text];
        return bear;
    } else if ([identifier isEqualToString:kEnglishSwitcherIdentifier]) {
        NSCustomTouchBarItem *panda =
            [[NSCustomTouchBarItem alloc] initWithIdentifier:kEnglishSwitcherIdentifier];
        panda.view =
            [NSButton buttonWithTitle:@"\U0001f1fa\U0001f1f8" target:self action:@selector(present:)];
        return panda;
    } else {
        return nil;
    }
}

- (void)setTextInTouchBarLabel {
    static BOOL isRequestInProgress = NO; // Флаг для отслеживания выполнения запроса

    if (isRequestInProgress) {
        // Если запрос уже выполняется, выходим из метода
        return;
    }

    isRequestInProgress = YES; // Устанавливаем флаг в состояние "выполняется"

    @autoreleasepool {
        NSURL *url = [NSURL URLWithString:@"http://localhost:3333"]; // Замените на URL вашего API

        NSURLRequest *request = [NSURLRequest requestWithURL:url];

        NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
            isRequestInProgress = NO; // Устанавливаем флаг в состояние "не выполняется"

            if (error) {
                NSLog(@"Ошибка: %@", error.localizedDescription);
                return;
            }

            // Парсинг JSON-ответа
            NSError *jsonError;
            NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError];
            if (jsonError) {
                NSLog(@"Ошибка при парсинге JSON: %@", jsonError.localizedDescription);
                return;
            }

            // Получение значения поля "text" и вывод в консоль
            NSString *text = [NSString stringWithFormat:@"\u270F\uFE0F: %@", json[@"text"]];

            NSLog(@"Значение поля \"text\": %@", text);
            dispatch_async(dispatch_get_main_queue(), ^{
                // Обновит содержимое тачбара
                NSCustomTouchBarItem *bear = [self.groupTouchBar itemForIdentifier:kEnglishTextIdentifier];
                if (bear && [bear.view isKindOfClass:[NSTextField class]]) {
                    NSTextField *textField = (NSTextField *)bear.view;
                    [textField setStringValue:text];
                }
            });
        }];

        [task resume];
    }
}


- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // Создаем таймер и сохраняем ссылку на него
    _textUpdateTimer = [NSTimer scheduledTimerWithTimeInterval:0.2  target:self selector:@selector(setTextInTouchBarLabel) userInfo:nil repeats:YES];
    
    DFRSystemModalShowsCloseBoxWhenFrontMost(YES);

    NSCustomTouchBarItem *panda =
        [[NSCustomTouchBarItem alloc] initWithIdentifier:kEnglishSwitcherIdentifier];
    panda.view = [NSButton buttonWithTitle:@"\U0001f1fa\U0001f1f8" target:self action:@selector(present:)];
    [NSTouchBarItem addSystemTrayItem:panda];
    DFRElementSetControlStripPresenceForIdentifier(kEnglishSwitcherIdentifier, YES);
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Остановка таймера при завершении приложения
    [_textUpdateTimer invalidate];
    _textUpdateTimer = nil;
}

@end

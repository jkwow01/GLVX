#import "GLVXWindowController.h"
#import "GLVXView.h"
#import "glv.h"

#pragma mark Private members

@interface GLVXWindowController ()
- (void)applyModifierKey:(NSEvent *)theEvent;
- (void)processKeyEvent:(NSEvent *)theEvent;
- (void)processMouseEvent:(NSEvent *)theEvent;
@end

#pragma mark
#pragma mark Class implementation

@implementation GLVXWindowController

#pragma mark Initialization

- (id)initWithGLV:(GLVREF)glv title:(NSString *)title
{
    glv::GLV& top = glv::Dereference(glv);
    int width = top.width();
    int height = top.height();
    
    // Main screen size.
    CGSize screenSize = [NSScreen mainScreen].frame.size;
    
    // Place the content at the center of the screen.
    NSRect contentRect;
    contentRect.origin.x = (screenSize.width - width) / 2;
    contentRect.origin.y = (screenSize.height - height) / 2;
    contentRect.size = CGSizeMake(width, height);
    
    // Create an empty window.
    NSUInteger styleMask = NSTitledWindowMask | NSClosableWindowMask | NSMiniaturizableWindowMask | NSResizableWindowMask;
    NSWindow *window = [[NSWindow alloc] initWithContentRect:contentRect styleMask:styleMask backing:NSBackingStoreBuffered defer:YES];
    if (!window) return self;
    
    // Create itself.
    self = [super initWithWindow:window];
    if (!self) return self;
    
    // Create a GLVXView instance and initialize the window.
    window.contentView = [[GLVXView alloc] initWithGLV:glv frame:contentRect];
    window.delegate = self;
    window.title = title;
    
    // Initialize the GLV instance.
    _glv = glv;
    top.extent(width, height);
    top.broadcastEvent(glv::Event::WindowCreate);
    
    return self;
}

#pragma mark Window handling events

- (void)windowDidResize:(NSNotification *)notification
{
    glv::GLV& target = glv::Dereference(_glv);
    CGSize size = [self.window.contentView frame].size;
    target.extent(size.width, size.height);
    target.broadcastEvent(glv::Event::WindowResize);
}

#pragma mark Key events

- (void)applyModifierKey:(NSEvent *)theEvent
{
    glv::GLV& target = glv::Dereference(_glv);
    NSUInteger mod = theEvent.modifierFlags;
    target.setKeyModifiers(mod & NSShiftKeyMask,
                           mod & NSAlternateKeyMask,
                           mod & NSControlKeyMask,
                           mod & NSAlphaShiftKeyMask,
                           mod & NSCommandKeyMask);
}

- (void)processKeyEvent:(NSEvent *)theEvent
{
    glv::GLV& target = glv::Dereference(_glv);

    [self applyModifierKey:theEvent];
    
    unsigned int key = [theEvent.charactersIgnoringModifiers characterAtIndex:0];
    if (theEvent.type == NSKeyDown)
    {
        target.setKeyDown(key);
    }
    else if (theEvent.type == NSKeyUp)
    {
        target.setKeyUp(key);
    }
    
    target.propagateEvent();
}

- (void)keyDown:(NSEvent *)theEvent
{
    [self processKeyEvent:theEvent];
}

- (void)keyUp:(NSEvent *)theEvent
{
    [self processKeyEvent:theEvent];
}

#pragma mark Mouse events

- (void)mouseDown:(NSEvent *)theEvent
{
    [self processMouseEvent:theEvent];
}

- (void)mouseUp:(NSEvent *)theEvent
{
    [self processMouseEvent:theEvent];
}

- (void)mouseDragged:(NSEvent *)theEvent
{
    [self processMouseEvent:theEvent];
}

- (void)processMouseEvent:(NSEvent *)theEvent
{
    glv::GLV& target = glv::Dereference(_glv);
    
    [self applyModifierKey:theEvent];
    
    // Flip vertically.
    NSPoint point = theEvent.locationInWindow;
    CGSize size = [self.window.contentView frame].size;
    point.y = size.height - point.y;
    
    glv::space_t relx = point.x;
    glv::space_t rely = point.y;
    
    if (theEvent.type == NSLeftMouseDown)
    {
        target.setMouseDown(relx, rely, glv::Mouse::Left, 0);
    }
    else if (theEvent.type == NSLeftMouseDragged)
    {
        target.setMouseMotion(relx, rely, glv::Event::MouseDrag);
    }
    else if (theEvent.type == NSLeftMouseUp)
    {
        target.setMouseUp(relx, rely, glv::Mouse::Left, 0);
    }
    
    target.setMousePos(point.x, point.y, relx, rely);
    target.propagateEvent();
}

@end

//
//  MPOutlineViewController.m
//  MacPass
//
//  Created by michael starke on 19.02.13.
//  Copyright (c) 2013 HicknHack Software GmbH. All rights reserved.
//

#import "MPOutlineViewController.h"
#import "MPOutlineViewDelegate.h"
#import "MPOutlineDataSource.h"
#import "MPDocument.h"
#import "MPAppDelegate.h"
#import "KdbLib.h"
#import "KdbGroup+Undo.h"
#import "MPContextMenuHelper.h"
#import "MPConstants.h"
#import "HNHGradientView.h"


@interface MPOutlineViewController () {
  BOOL _bindingEstablished;
}
@property (assign) IBOutlet NSOutlineView *outlineView;

@property (retain) NSTreeController *treeController;
@property (retain) MPOutlineDataSource *datasource;
@property (retain) MPOutlineViewDelegate *outlineDelegate;
@property (retain) NSMenu *menu;

@end

@implementation MPOutlineViewController

- (id)init {
  return [[MPOutlineViewController alloc] initWithNibName:@"OutlineView" bundle:nil];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
  self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
  if (self) {
    _treeController = [[NSTreeController alloc] init];
    _bindingEstablished = NO;
    _outlineDelegate = [[MPOutlineViewDelegate alloc] init];
    _datasource = [[MPOutlineDataSource alloc] init];
  }
  
  return self;
}

- (void)dealloc
{
  self.datasource = nil;
  self.outlineDelegate = nil;
  self.menu = nil;
  [super dealloc];
}

- (void)didLoadView {
  [self.outlineView setDelegate:self.outlineDelegate];
  [self.outlineView setMenu:[self _contextMenu]];
  [self.outlineView setAllowsEmptySelection:YES];
  [self.outlineView setFloatsGroupRows:NO];
  [_outlineView registerForDraggedTypes:@[ MPPasteBoardType ]];
  [self.outlineView setDraggingSourceOperationMask:NSDragOperationEvery forLocal:YES];
  [_bottomBar setBorderType:HNHBorderTop];
}

- (void)showOutline {
  if(!_bindingEstablished) {
    MPDocument *document = [[self windowController] document];
    [_treeController setChildrenKeyPath:@"groups"];
    [_treeController bind:NSContentBinding toObject:document withKeyPath:@"root" options:nil];
    [_outlineView bind:NSContentBinding toObject:_treeController withKeyPath:@"arrangedObjects" options:nil];
    [_outlineView setDataSource:self.datasource];
    _bindingEstablished = YES;
  }
  NSTreeNode *node = [_outlineView itemAtRow:0];
  [_outlineView expandItem:node expandChildren:NO];
}

- (void)clearSelection {
  [self.outlineView deselectAll:nil];
}

- (NSMenu *)_contextMenu {
  NSMenu *menu = [[NSMenu alloc] init];
  NSArray *items = [MPContextMenuHelper contextMenuItemsWithItems:MPContextMenuMinimal];
  for(NSMenuItem *item in items) {
    [menu addItem:item];
  }
  return [menu autorelease];
}

- (void)createGroup:(id)sender {
  KdbGroup *group = [self _clickedOrSelectedGroup];
  MPDocument *document = [[self windowController] document];
  if(!group) {
    group = document.root;
  }
  BOOL isFistGroup = [document.root.groups count] == 0;
  [document createGroup:group];
  /*
   TODO: Find out if a lower hierachy node was the first child
   and auto-expand that item too
   */
  if(isFistGroup) {
    NSTreeNode *node = [_outlineView itemAtRow:0];
    [_outlineView expandItem:node expandChildren:NO];
  }
}

- (void)createEntry:(id)sender {
  KdbGroup *group = [self _clickedOrSelectedGroup];
  if(!group.parent) {
    return; // Entries are not allowed in root group
  }
  if(group) {
    MPDocument *document = [[self windowController] document];
    [document createEntry:group];
  }
}

- (void)deleteEntry:(id)sender {
  KdbGroup *group = [self _clickedOrSelectedGroup];
  if(group && group.parent) {
    [group.parent removeGroupUndoable:group];    
  }
}

- (KdbGroup *)_clickedOrSelectedGroup {
  NSInteger row = [self.outlineView clickedRow];
  if( row < 0 ) {
    row = [self.outlineView selectedRow];
  }
  return [[self.outlineView itemAtRow:row] representedObject];
}

@end

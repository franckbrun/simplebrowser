//
//  AppDelegate.m
//  SimpleBrowser
//
//  Created by Franck Brun on 06/12/2018.
//  Copyright © 2018 MoxAdventu. All rights reserved.
//

#import "AppDelegate.h"

static NSString *NameKey = @"Name";
static NSString *InfosKey = @"Infos";
static NSString *Children = @"Children";
static NSString *FullPath = @"FullPath";

@interface AppDelegate () <NSOutlineViewDelegate, NSOutlineViewDataSource, NSTableViewDelegate, NSTableViewDataSource>

@property (weak) IBOutlet NSWindow *window;

@property(weak) IBOutlet NSOutlineView *masterOutlineView;

@property(weak) IBOutlet NSTableView *detailsTableView;

@property(strong) NSMutableArray<NSMutableDictionary *> *contents;

@property(strong) NSMutableArray<NSDictionary *> *detailsContents;

@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
  
  self.masterOutlineView.dataSource = self;
  self.masterOutlineView.delegate = self;
  
  self.detailsTableView.dataSource = self;
  self.detailsTableView.delegate = self;
  
  self.contents = [self contentsOfPath:[@"~" stringByExpandingTildeInPath]];
  [self.masterOutlineView reloadData];
  
  [self clearDetails];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
}

- (NSMutableArray *)contentsOfPath:(NSString *)path {

  NSMutableArray *list = [NSMutableArray array];
  
  NSURL *folderUrl = [NSURL fileURLWithPath:path];
  NSFileManager *fm = [NSFileManager defaultManager];

  NSArray *keys = @[NSURLIsSymbolicLinkKey,
                    NSURLNameKey,
                    NSURLIsDirectoryKey,
                    NSURLFileSizeKey,
                    NSURLIsAliasFileKey];

  NSInteger options =
  NSDirectoryEnumerationSkipsSubdirectoryDescendants
  | NSDirectoryEnumerationSkipsHiddenFiles
  | NSDirectoryEnumerationSkipsPackageDescendants;

  NSDirectoryEnumerator *enumerator = [fm enumeratorAtURL:folderUrl includingPropertiesForKeys:keys
                                                  options:options
                                             errorHandler:nil];

  for (NSURL *fileUrl in enumerator) {
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithDictionary:[fileUrl resourceValuesForKeys:keys error:nil]];
    dict[FullPath] = fileUrl.path;
    [list addObject:dict];
  }
  
  return list;
}

#pragma mark - utils

- (void)clearDetails {
  self.detailsContents = [@[] mutableCopy];
  [self.detailsTableView reloadData];
}

- (void)fillDetailsWith:(NSDictionary *)item {
  [self clearDetails];
  for (NSString *key in item) {
    NSDictionary *values = nil;
    if ([key isEqualToString:Children]) {
      NSArray *children = item[Children];
      values = @{NameKey : Children, InfosKey : [NSString stringWithFormat:@"%lu files...", (unsigned long)children.count] };
    } else {
      values = @{NameKey : key, InfosKey : [NSString stringWithFormat:@"%@", item[key]] };
    }
    [self.detailsContents addObject:values];
  }
  
  [self.detailsTableView reloadData];
}

#pragma mark - Outline View Datasource and Delegate

- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item {
  if (item == nil) return self.contents.count;
  else {
    NSNumber *isDir = item[NSURLIsDirectoryKey];
    if (isDir.boolValue && item[Children] == nil) {
      NSArray *children = [self contentsOfPath:item[FullPath]];
      item[Children] = children;
      [self fillDetailsWith:item];
      dispatch_async(dispatch_get_main_queue(), ^{
        [self.masterOutlineView reloadItem:item];
      });
    }
    NSArray *children = item[Children];
    return children ? children.count : 0;
  }
  return 0;
}

- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item {
  if (item == nil) return self.contents[index];
  else {
    NSArray *children = item[Children];
    return children ? children[index] : nil;
  }
  return nil;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item {
  NSNumber *isDir = item[NSURLIsDirectoryKey];
  return isDir.boolValue;
}

- (NSView *)outlineView:(NSOutlineView *)outlineView viewForTableColumn:(NSTableColumn *)tableColumn item:(id)item {
  NSTableCellView *cell = [outlineView makeViewWithIdentifier:@"DataCell" owner:self];
  NSNumber *isDir = item[NSURLIsDirectoryKey];
  cell.imageView.image = [NSImage imageNamed: isDir.boolValue ? NSImageNameFolder : NSImageNamePathTemplate];
  cell.textField.stringValue = item[NSURLNameKey];
  return cell;
}

- (void)outlineViewSelectionDidChange:(NSNotification *)notification {
  if (self.masterOutlineView.selectedRow == -1) return;
  NSDictionary *item = [self.masterOutlineView itemAtRow:self.masterOutlineView.selectedRow];
  [self fillDetailsWith:item];
}

- (BOOL)outlineView:(NSOutlineView *)outlineView shouldSelectItem:(id)item {
  return YES;
}

#pragma mark - TableView Datasource and Delegate

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
  return self.detailsContents.count;
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
  NSTableCellView *cell = [tableView makeViewWithIdentifier:tableColumn.identifier owner:self];
  NSDictionary *infos = self.detailsContents[row];
  cell.textField.stringValue = infos[tableColumn.identifier];
  return cell;
}

- (void)outlineViewItemWillExpand:(NSNotification *)notification {
  NSLog(@"outlineViewItemWillExpand");
}

- (void)outlineViewItemDidExpand:(NSNotification *)notification {
  NSLog(@"outlineViewItemDidExpand");
}

- (void)outlineViewItemWillCollapse:(NSNotification *)notification {
  NSLog(@"outlineViewItemWillCollapse");
}

- (void)outlineViewItemDidCollapse:(NSNotification *)notification {
  NSLog(@"outlineViewItemDidCollapse");
}

@end

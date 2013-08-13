//
//  AllGroupsViewController.h
//  Stiri
//
//  Created by Stoica Vlad on 7/24/13.
//  Copyright (c) 2013 Stoica Vlad. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SideSwipeTableViewController.h"

@interface NewsGroupViewController : SideSwipeTableViewController <UITableViewDelegate, UITableViewDataSource>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (nonatomic,strong) NSManagedObjectContext* managedObjectContext;

@property (strong, nonatomic) NSArray *buttonData;
@property (strong, nonatomic) NSMutableArray *buttons;

@end

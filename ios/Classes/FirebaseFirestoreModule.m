/**
 * titanium-firebase-firestore
 *
 * Created by Hans Knöchel
 */

#import "FirebaseFirestoreModule.h"
#import "TiBase.h"
#import "TiHost.h"
#import "TiUtils.h"

#import <FirebaseFirestore/FirebaseFirestore.h>

@implementation FirebaseFirestoreModule

#pragma mark Internal

- (id)moduleGUID
{
  return @"01ba870c-6842-4b23-a8db-eb1eaffebf3f";
}

- (NSString *)moduleId
{
  return @"firebase.firestore";
}

- (void)addDocument:(id)params
{
  ENSURE_SINGLE_ARG(params, NSDictionary);

  KrollCallback *callback = params[@"callback"];
  NSString *collection = params[@"collection"];
  NSDictionary *data = params[@"data"];

  __block FIRDocumentReference *ref = [[FIRFirestore.firestore collectionWithPath:collection] addDocumentWithData:data
                                                                   completion:^(NSError * _Nullable error) {
  if (error != nil) {
      [callback call:@[@{ @"success": @(NO), @"error": error.localizedDescription }] thisObject:self];
      return;
    }

    [callback call:@[@{ @"success": @(YES), @"documentID": NULL_IF_NIL(ref.documentID), @"documentPath": NULL_IF_NIL(ref.path) }] thisObject:self];
  }];
}

- (void)getDocuments:(id)params
{
  ENSURE_SINGLE_ARG(params, NSDictionary);

  KrollCallback *callback = params[@"callback"];
  NSString *collection = params[@"collection"];

  [[FIRFirestore.firestore collectionWithPath:collection] getDocumentsWithCompletion:^(FIRQuerySnapshot * _Nullable snapshot, NSError * _Nullable error) {
    if (error != nil) {
      [callback call:@[@{ @"success": @(NO), @"error": error.localizedDescription }] thisObject:self];
      return;
    }

    NSMutableArray<NSDictionary<NSString *, id> *> *documents = [NSMutableArray arrayWithCapacity:snapshot.documents.count];

    [snapshot.documents enumerateObjectsUsingBlock:^(FIRQueryDocumentSnapshot * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
      [documents addObject:[obj data]];
    }];

    [callback call:@[@{ @"success": @(YES), @"documents": documents }] thisObject:self];
  }];
}

- (void)updateDocument:(id)params
{
  ENSURE_SINGLE_ARG(params, NSDictionary);

  KrollCallback *callback = params[@"callback"];
  NSString *collection = params[@"collection"];
  NSDictionary *data = params[@"data"];
  NSString *document = params[@"document"];

  [[[FIRFirestore.firestore collectionWithPath:collection] documentWithPath:document] updateData:data
                                                                                      completion:^(NSError * _Nullable error) {
    if (error != nil) {
      [callback call:@[@{ @"success": @(NO), @"error": error.localizedDescription }] thisObject:self];
      return;
    }

    [callback call:@[@{ @"success": @(YES) }] thisObject:self];
  }];
}

- (void)deleteDocument:(id)params
{
  ENSURE_SINGLE_ARG(params, NSDictionary);

  KrollCallback *callback = params[@"callback"];
  NSString *collection = params[@"collection"];
  NSDictionary *data = params[@"data"];
  NSString *document = params[@"document"];

  [[[FIRFirestore.firestore collectionWithPath:collection] documentWithPath:document] deleteDocumentWithCompletion:^(NSError * _Nullable error) {
    if (error != nil) {
      [callback call:@[@{ @"success": @(NO), @"error": error.localizedDescription }] thisObject:self];
      return;
    }

    [callback call:@[@{ @"success": @(YES) }] thisObject:self];
  }];
}

@end

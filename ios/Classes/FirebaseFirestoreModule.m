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
  NSDictionary *data = params[@"data"]; // TODO: Parse "FIRFieldValue" proxy types

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

- (void)getSingleDocument:(id)params
{
  ENSURE_SINGLE_ARG(params, NSDictionary);

  KrollCallback *callback = params[@"callback"];
  NSString *collection = params[@"collection"];
  NSString *document = params[@"document"];

  FIRDocumentReference *documentReference = [[FIRFirestore.firestore collectionWithPath:collection] documentWithPath:document];

  [documentReference getDocumentWithCompletion:^(FIRDocumentSnapshot * _Nullable snapshot, NSError * _Nullable error) {
    if (error != nil) {
      [callback call:@[@{ @"success": @(NO), @"error": error.localizedDescription }] thisObject:self];
      return;
    }

    [callback call:@[@{ @"success": @(YES), @"document": [snapshot data] }] thisObject:self];
  }];
}

- (void)updateDocument:(id)params
{
  ENSURE_SINGLE_ARG(params, NSDictionary);

  KrollCallback *callback = params[@"callback"];
  NSString *collection = params[@"collection"];
  NSDictionary *data = params[@"data"]; // TODO: Parse "FIRFieldValue" proxy types
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

- (FirebaseFirestoreFieldValueProxy *)increment:(id)value
{
  ENSURE_SINGLE_ARG(value, NSNumber);
  
  FIRFieldValue *fieldValue = [FIRFieldValue fieldValueForIntegerIncrement:[TiUtils intValue:value]];
  return [[FirebaseFirestoreFieldValueProxy alloc] _initWithPageContext:pageContext andFieldValue:fieldValue];
}

- (void)queryDocuments:(id)params
{
  ENSURE_SINGLE_ARG(params, NSDictionary);

  KrollCallback *callback = params[@"callback"];
  NSString *collection = params[@"collection"];
  NSString *document = params[@"document"];
  NSString *field = params[@"field"];
  NSString *opStr = params[@"opStr"];
  NSString *value = params[@"value"];
  NSMutableArray *filters = params[@"filters"];
    
    
    FIRQuery *query;

    if ([opStr isEqualToString:@"=="]) {
              query = [[FIRFirestore.firestore collectionWithPath:collection] queryWhereField:field isEqualTo:value];
       } else if ([opStr isEqualToString:@">"]) {
          query = [[FIRFirestore.firestore collectionWithPath:collection] queryWhereField:field isGreaterThan:value];
       } else if ([opStr isEqualToString:@">="]) {
          query = [[FIRFirestore.firestore collectionWithPath:collection] queryWhereField:field isGreaterThanOrEqualTo:value];
       } else if ([opStr isEqualToString:@"<"]) {
          query = [[FIRFirestore.firestore collectionWithPath:collection] queryWhereField:field isLessThan:value];
       } else if ([opStr isEqualToString:@"<="]) {
          query = [[FIRFirestore.firestore collectionWithPath:collection] queryWhereField:field isLessThanOrEqualTo:value];
       } else if ([opStr isEqualToString:@"in"]) {
          query = [[FIRFirestore.firestore collectionWithPath:collection] queryWhereField:field in:filters];
       }else if ([opStr isEqualToString:@"array-contains"]) {
          query = [[FIRFirestore.firestore collectionWithPath:collection] queryWhereField:field arrayContains:filters];
       }else if ([opStr isEqualToString:@"array-contains-any"]) {
          query = [[FIRFirestore.firestore collectionWithPath:collection] queryWhereField:field arrayContainsAny:filters];
       }else {
           NSLog(@"Unknown operator type %s", [self convertString:opStr]);
       }


 
 [ query getDocumentsWithCompletion:^(FIRQuerySnapshot * _Nullable snapshot, NSError * _Nullable error) {
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
@end

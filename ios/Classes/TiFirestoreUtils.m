//
//  TiFirestoreUtils.m
//  titanium-firebase-firestore
//
//  Created by Hans Knöchel on 06.12.22.
//

#import <FirebaseFirestore/FirebaseFirestore.h>
#import "FirebaseFirestoreModule.h"
#import "TiBase.h"
#import "TiFirestoreUtils.h"
#import "TiHost.h"
#import "TiUtils.h"

@implementation TiFirestoreUtils


static NSString *const KEY_PATH = @"path";
static NSString *const KEY_DATA = @"data";
static NSString *const KEY_EXISTS = @"exists";
static NSString *const KEY_CHANGES = @"changes";
static NSString *const KEY_METADATA = @"metadata";
static NSString *const KEY_DOCUMENTS = @"documents";
static NSString *const KEY_DOC_CHANGE_TYPE = @"type";
static NSString *const KEY_DOC_CHANGE_DOCUMENT = @"doc";
static NSString *const KEY_DOC_CHANGE_NEW_INDEX = @"ni";
static NSString *const KEY_DOC_CHANGE_OLD_INDEX = @"oi";

// Document Change Types
static NSString *const CHANGE_ADDED = @"a";
static NSString *const CHANGE_MODIFIED = @"m";
static NSString *const CHANGE_REMOVED = @"r";

enum TYPE_MAP {
  INT_NAN,
  INT_NEGATIVE_INFINITY,
  INT_POSITIVE_INFINITY,
  INT_NULL,
  INT_DOCUMENTID,
  INT_BOOLEAN_TRUE,
  INT_BOOLEAN_FALSE,
  INT_DOUBLE,
  INT_STRING,
  INT_STRING_EMPTY,
  INT_ARRAY,
  INT_REFERENCE,
  INT_GEOPOINT,
  INT_TIMESTAMP,
  INT_BLOB,
  INT_FIELDVALUE,
  INT_OBJECT,
  INT_INTEGER,
  INT_NEGATIVE_ZERO,
  INT_UNKNOWN = -999,
};


+ (NSDictionary *)mappedFirestoreValue:(NSDictionary<NSString *, id> *)value {
  NSMutableDictionary *result = [[NSMutableDictionary alloc] init];

  [value enumerateKeysAndObjectsUsingBlock:^(id _Nonnull key, id _Nonnull value,
                                             BOOL *_Nonnull stop) {
    // Handle timestamps as a native type
    if ([value isKindOfClass:[FIRTimestamp class]]) {
      FIRTimestamp *timestamp = (FIRTimestamp *)value;
      result[key] = @{
        @"seconds" : @(timestamp.seconds),
        @"nanoseconds" : @(timestamp.nanoseconds)
      };
      // Handle all other values directly
    } else {
      result[key] = value;
    }
  }];

  return result;
}



// Converts a Native Dictionary to JS map
+ (NSDictionary *)serializeDictionary:(NSDictionary *)dictionary {
  NSMutableDictionary *dictValues = [[NSMutableDictionary alloc] init];

  [dictionary
      enumerateKeysAndObjectsUsingBlock:^(id _Nonnull key, id _Nonnull obj, BOOL *_Nonnull stop) {
        dictValues[key] = [self buildTypeMap:obj];
      }];

  return dictValues;
}

+ (NSArray *)serializeArray:(NSArray *)array {
  NSMutableArray *arrayValues = [[NSMutableArray alloc] init];

  [array enumerateObjectsUsingBlock:^(id _Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
    arrayValues[idx] = [self buildTypeMap:obj];
  }];

  return arrayValues;
}

// Native value to JS map
+ (NSArray *)buildTypeMap:(id)value {
  NSMutableArray *typeArray = [[NSMutableArray alloc] init];

  // null
  if (value == nil || [value isKindOfClass:[NSNull class]]) {
    typeArray[0] = @(INT_NULL);
    return typeArray;
  }

  // String
  if ([value isKindOfClass:[NSString class]]) {
    if ([value length] == 0) {
      typeArray[0] = @(INT_STRING_EMPTY);
    } else {
      typeArray[0] = @(INT_STRING);
      typeArray[1] = value;
    }
    return typeArray;
  }

  // Object
  if ([value isKindOfClass:[NSDictionary class]]) {
    typeArray[0] = @(INT_OBJECT);
    typeArray[1] = [self serializeDictionary:value];
    return typeArray;
  }

  // Array
  if ([value isKindOfClass:[NSArray class]]) {
    typeArray[0] = @(INT_ARRAY);
    typeArray[1] = [self serializeArray:value];
    return typeArray;
  }

  // DocumentReference
  if ([value isKindOfClass:[FIRDocumentReference class]]) {
    typeArray[0] = @(INT_REFERENCE);
    FIRDocumentReference *ref = (FIRDocumentReference *)value;
    typeArray[1] = [ref path];
    return typeArray;
  }

  // GeoPoint
  if ([value isKindOfClass:[FIRGeoPoint class]]) {
    typeArray[0] = @(INT_GEOPOINT);
    NSMutableArray *geoPointArray = [[NSMutableArray alloc] init];
    FIRGeoPoint *geoPoint = (FIRGeoPoint *)value;
    geoPointArray[0] = @([geoPoint latitude]);
    geoPointArray[1] = @([geoPoint longitude]);
    typeArray[1] = geoPointArray;
    return typeArray;
  }

  // Timestamp
  if ([value isKindOfClass:[FIRTimestamp class]]) {
    typeArray[0] = @(INT_TIMESTAMP);
    NSMutableArray *timestampArray = [[NSMutableArray alloc] init];
    FIRTimestamp *firTimestamp = (FIRTimestamp *)value;
    int64_t seconds = (int64_t)firTimestamp.seconds;
    int32_t nanoseconds = (int32_t)firTimestamp.nanoseconds;
    timestampArray[0] = @(seconds);
    timestampArray[1] = @(nanoseconds);
    typeArray[1] = timestampArray;
    return typeArray;
  }

  // number / boolean / infinity / nan
  if ([value isKindOfClass:[NSNumber class]]) {
    NSNumber *number = (NSNumber *)value;

    // Infinity
    if ([number isEqual:@(INFINITY)]) {
      typeArray[0] = @(INT_POSITIVE_INFINITY);
      return typeArray;
    }

    // -Infinity
    if ([number isEqual:@(-INFINITY)]) {
      typeArray[0] = @(INT_NEGATIVE_INFINITY);
      return typeArray;
    }

    // Boolean True
    if (number == [NSValue valueWithPointer:(void *)kCFBooleanTrue]) {
      typeArray[0] = @(INT_BOOLEAN_TRUE);
      return typeArray;
    }

    // Boolean False
    if (number == [NSValue valueWithPointer:(void *)kCFBooleanFalse]) {
      typeArray[0] = @(INT_BOOLEAN_FALSE);
      return typeArray;
    }

    // NaN
    if ([[value description].lowercaseString isEqual:@"nan"]) {
      typeArray[0] = @(INT_NAN);
      return typeArray;
    }

    // Number
    typeArray[0] = @(INT_DOUBLE);
    typeArray[1] = value;
    return typeArray;
  }

  // Blob / Base64
  if ([value isKindOfClass:[NSData class]]) {
    NSData *blob = (NSData *)value;
    typeArray[0] = @(INT_BLOB);
    typeArray[1] = [blob base64EncodedStringWithOptions:0];
    return typeArray;
  }

  typeArray[0] = @(INT_UNKNOWN);
  return typeArray;
}

// Parses JS Object into Native Dict
+ (NSDictionary *)parseNSDictionary:(FIRFirestore *)firestore
                         dictionary:(NSDictionary *)dictionary {
  NSMutableDictionary *dictValues = [[NSMutableDictionary alloc] init];

  if (dictionary == nil) return dictValues;

  [dictionary
      enumerateKeysAndObjectsUsingBlock:^(id _Nonnull key, id _Nonnull obj, BOOL *_Nonnull stop) {
        dictValues[key] = [self parseTypeMap:firestore typeMap:obj];
      }];

  return dictValues;
}

// Parses JS Array to Native Array
+ (NSArray *)parseNSArray:(FIRFirestore *)firestore array:(NSArray *)array {
  NSMutableArray *arrayValues = [[NSMutableArray alloc] init];

  if (array == nil) return arrayValues;

  [array enumerateObjectsUsingBlock:^(id _Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
    [arrayValues addObject:[self parseTypeMap:firestore typeMap:obj]];
  }];

  return arrayValues;
}

// Converts a JS array [INT, value] to native value
+ (id)parseTypeMap:(FIRFirestore *)firestore typeMap:(NSArray *)typeMap {
  NSInteger value = [typeMap[0] integerValue];

  switch (value) {
    case INT_NAN:
      return @(NAN);
    case INT_NEGATIVE_INFINITY:
      return @(-INFINITY);
    case INT_POSITIVE_INFINITY:
      return @(INFINITY);
    case INT_NULL:
      return [NSNull null];
    case INT_DOCUMENTID:
      return [FIRFieldPath documentID];
    case INT_BOOLEAN_TRUE:
      return @(YES);
    case INT_BOOLEAN_FALSE:
      return @(NO);
    case INT_NEGATIVE_ZERO:
      return @(-0.0);
    case INT_INTEGER:
      return @([typeMap[1] longLongValue]);
    case INT_DOUBLE:
      return @([typeMap[1] doubleValue]);
    case INT_STRING:
      return typeMap[1];
    case INT_STRING_EMPTY:
      return @"";
    case INT_ARRAY:
      return [self parseNSArray:firestore array:typeMap[1]];
    case INT_REFERENCE:
      return [firestore documentWithPath:typeMap[1]];
    case INT_GEOPOINT: {
      NSArray *geopoint = typeMap[1];
      return [[FIRGeoPoint alloc] initWithLatitude:[geopoint[0] doubleValue]
                                         longitude:[geopoint[1] doubleValue]];
    }
    case INT_TIMESTAMP: {
      NSArray *timestamp = typeMap[1];
      int64_t seconds = [timestamp[0] longLongValue];
      int32_t nanoseconds = [timestamp[1] intValue];
      return [[FIRTimestamp alloc] initWithSeconds:seconds nanoseconds:nanoseconds];
    }
    case INT_BLOB:
      return [[NSData alloc] initWithBase64EncodedData:typeMap[1] options:0];
    case INT_FIELDVALUE: {
      NSArray *fieldValueArray = typeMap[1];
      NSString *fieldValueType = fieldValueArray[0];

      if ([fieldValueType isEqualToString:@"timestamp"]) {
        return [FIRFieldValue fieldValueForServerTimestamp];
      }

      if ([fieldValueType isEqualToString:@"increment"]) {
        return [FIRFieldValue fieldValueForDoubleIncrement:[fieldValueArray[1] doubleValue]];
      }

      if ([fieldValueType isEqualToString:@"delete"]) {
        return [FIRFieldValue fieldValueForDelete];
      }

      if ([fieldValueType isEqualToString:@"array_union"]) {
        NSArray *elements = [self parseNSArray:firestore array:fieldValueArray[1]];
        return [FIRFieldValue fieldValueForArrayUnion:elements];
      }

      if ([fieldValueType isEqualToString:@"array_remove"]) {
        NSArray *elements = [self parseNSArray:firestore array:fieldValueArray[1]];
        return [FIRFieldValue fieldValueForArrayRemove:elements];
      }

      return nil;
    }
    case INT_OBJECT:
      return [self parseNSDictionary:firestore dictionary:typeMap[1]];
    case INT_UNKNOWN:
    default:
      return nil;
  }
}

@end

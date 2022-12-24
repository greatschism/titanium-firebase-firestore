//
//  TiFirestoreUtils.h
//  titanium-firebase-firestore
//
//  Created by Hans Knöchel on 06.12.22.
//

#import <Foundation/Foundation.h>
#import "FirebaseFirestoreFieldValueProxy.h"


NS_ASSUME_NONNULL_BEGIN

@interface TiFirestoreUtils : NSObject

+ (NSDictionary *)mappedFirestoreValue:(id)value;


+ (NSDictionary *)serializeDictionary:(NSDictionary *)dictionary;

+ (NSArray *)serializeArray:(NSArray *)array;

+ (NSArray *)buildTypeMap:(id)value;

+ (NSDictionary *)parseNSDictionary:(FIRFirestore *)firestore dictionary:(NSDictionary *)dictionary;

+ (NSArray *)parseNSArray:(FIRFirestore *)firestore array:(NSArray *)array;

+ (id)parseTypeMap:(FIRFirestore *)firestore typeMap:(NSArray *)typeMap;

@end

NS_ASSUME_NONNULL_END

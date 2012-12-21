//
//  EESQLiteStatement.h
//  EonilCocoaComplements-SQLite
//
//  Created by Hoon Hwangbo on 1/22/12.
//  Copyright (c) 2012 Eonil Company. All rights reserved.
//

#import				<Foundation/Foundation.h>








/*!
 @abstract
 Prepared statement.
 
 @discussion
 This is essentially a proxy object for compiled byte-code program in SQLite engine.
 
 @warning
 You MUST deallocate this object before hosting `EESQLiteDatabase` object
 deallocates. Because SQLite3 checks all the statements are finalized when
 it is dying. If any of them are still remains, it will raise an error,
 `EESQLiteDatabase` object will detect it and throw an exception.
 
 I recommend `@autoreleasepool` block to make it sure to be deallocated.
 */
@interface			EESQLiteStatement : NSObject
@property			(readonly,nonatomic)		NSString*		SQL;
/*!
 @abstract
 Steps processing of SQL command.
 
 @param
 error
 Any error while executing this method.
 
 @result
 Returns iterability.
 `YES` if the command need to be stepped more. Normally, this returned because 
 execution is not finished and has more steps to go.
 `NO` if the command finished, and cannot be iterated anymore.
 
 You can continue stepping only while this method returns `YES`.
 
 @note
 For any error cases, the `error` argument will be set. If it is `nil`, there's 
 no error.

 */
- (BOOL)			stepWithError:(NSError**)error;
- (BOOL)			step;

/*!
 @abstract
 Reset internal state of this statement to re-use.
 
 @param
 error
 Any error while executing this method.
 
 @discussion
 If you want to issue same command without re-compiling it again, 
 you can use this method to re-use it.
 */
- (BOOL)			resetWithError:(NSError**)error;
- (void)			reset;

@end











@interface			EESQLiteStatement (Querying)

- (NSUInteger)		dataCount;

////				Access as raw storage class.
////				If you try to read with different type with actual value stored in,
////				SQLite3 will try to convert values. Obviously not good for performance.
////				See here for conversion table:
////				http://www.sqlite.org/c3ref/column_blob.html
////
////				String access method supports only UTF-8. 
////				This means if the source data is stored in UTF-16, conversion will 
////				be occur and performance will be degraded.
////				Of course, SQLite3 supports UTF-16. No support for UTF-16 is my decision
////				to simplify class.
- (long long)		longLongValueForColumnIndex:(NSInteger)columnIndex;
- (NSInteger)		integerValueForColumnIndex:(NSInteger)columnIndex;		//	Size of `NSInteger` can be vary by the system.
- (double)			doubleValueForColumnIndex:(NSInteger)columnIndex;
- (NSString*)		stringValueForColumnIndex:(NSInteger)columnIndex;		//	Returning string is copied value.
- (NSData*)			dataValueForColumnIndex:(NSInteger)columnIndex;			//	Returning data is copied value.
- (BOOL)			isNullAtColumnIndex:(NSInteger)columnIndex;

/*!
 @abstract
 Read whole current row as dictionary.
 
 @discussion
 Access as collected and automatically typed object.
 Each field can be one of `NSData`, `NSString` or `NSNumber` which
 contains integral or floating point numbers.
 SQLite's `NULL` will be replaced with specified value.
 You can specify `nil` for replacement, and the field with `nil` value
 will not be stored in dictionary.
 String or binary data copied before return. So it's safe to keep them.
 This is a lot slower than access by raw storage class methods.
 */
- (NSDictionary*)	dictionaryValueReplacingNullsWithValue:(id)nullValue;
- (NSDictionary*)	dictionaryValue;	//	Set `nullValue` as `nil`.



@end











@interface			EESQLiteStatement (Mutation)

- (NSUInteger)		parameterCount;

- (BOOL)			setLongLongValue:(long long)value forParameterIndex:(NSInteger)parameterIndex error:(NSError**)error;
- (BOOL)			setIntegerValue:(NSInteger)value forParameterIndex:(NSInteger)parameterIndex error:(NSError**)error;		//	Size of `NSInteger` can be vary by the system.
- (BOOL)			setDoubleValue:(double)value forParameterIndex:(NSInteger)parameterIndex error:(NSError**)error;
- (BOOL)			setStringValue:(NSString*)value forParameterIndex:(NSInteger)parameterIndex error:(NSError**)error;
- (BOOL)			setDataValue:(NSData*)value forParameterIndex:(NSInteger)parameterIndex error:(NSError**)error;
- (BOOL)			setNullForParameterIndex:(NSInteger)parameterIndex error:(NSError**)error;

/*!
 If the `value` is `nil`, the parameter will be set to `NULL`.
 */
- (BOOL)			setValue:(id)value forParameterIndex:(NSInteger)parameterIndex error:(NSError**)error;
- (BOOL)			setValue:(id)value forParameterName:(NSString*)parameterName error:(NSError**)error;
//- (void)			setValuesFromArray:(NSArray*)valuesArray;
//- (void)			setDictionaryValue:(NSDictionary*)dictionaryValue;

- (BOOL)			clearParametersValuesWithError:(NSError**)error;

@end











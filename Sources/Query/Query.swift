//
//  Query.swift
//  EonilSQLite3
//
//  Created by Hoon H. on 9/15/14.
//
//

import Foundation




///	Abstracts an object which can produce a fragment of a query statement.
public protocol QueryExpressible {
	func express() -> Query.Expression
}








///	Safely and easily generate SQL queries.
public struct Query {
	
	public typealias	UniqueParameterNameGenerator	=	()->String							///<	Returns a unique name which is prefixed with `@` to build a parameter name.
	public typealias	ParameterValueEvaluation		=	()->Value
	
	
	
	static let	missingParameter	=	{ Debug.trapConvenientExtensionsError("Value for this parameter is intentionally missing. It must be provided later."); return Value.Null } as Query.ParameterValueEvaluation

	
	

	///	Represents a fragment of a query.
	public struct Expression : StringLiteralConvertible {
		let	code		=	""
		let	parameters	=	[] as [ParameterValueEvaluation]
		
		static let	empty				=	Expression(code: "", parameters: [])
		
		////
		
		init(_ code:String) {
			self.init(code: code, parameters: [])
		}
		init(code:String, parameters:[ParameterValueEvaluation]) {
			self.code		=	code
			self.parameters	=	parameters
		}
		
		
		public init(stringLiteral value: String) {
			self	=	Expression(code: value, parameters: [])
		}
		public init(extendedGraphemeClusterLiteral value: String) {
			self	=	Expression(code: value, parameters: [])
		}
		public init(unicodeScalarLiteral value: String) {
			self	=	Expression(code: value, parameters: [])
		}
		
		////
		
		static func ofParameterList(values:[ParameterValueEvaluation]) -> Expression {
			var	qs0	=	[] as [String]
			for _ in 0..<values.count {
				qs0.append("?")
			}
			let	qs2	=	join(", ", qs0)
			return	Expression(code: qs2, parameters: values)
		}
		static func concatenation(#separator:Expression, components:[Expression]) -> Expression {
			func add_with_sep(left:Expression, right:Expression) -> Expression {
				return	left + separator + right
			}
			
			switch components.count {
			case 0:		return	Expression.empty
			case 1:		return	components.first!
			default:	return	components[1..<components.count].reduce(components.first!, combine: add_with_sep)
			}
		}
	}
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	///	Represents names such as table or column.
	public struct Identifier : QueryExpressible, StringLiteralConvertible, Printable {
		public let	name:String
		
		public init(name:String) {
			precondition(find(name, "\"") == nil, "Identifiers which contains double-quote(\") are not currently supported by Swift layer.")
			
			self.name	=	name
		}
		
		public init(stringLiteral value: String) {
			self	=	Identifier(name: value)
		}
		public init(extendedGraphemeClusterLiteral value: String) {
			self	=	Identifier(name: value)
		}
		public init(unicodeScalarLiteral value: String) {
			self	=	Identifier(name: value)
		}
		
		
		public var description:String {
			get {
				let		x1	=	"\"\(name)\""
				return	x1
			}
		}
		
		public func express() -> Query.Expression {
			return	Expression(code: description, parameters: [])
		}

		public static func convertFromStringLiteral(value: String) -> Identifier {
			return	Identifier(name: value)
		}
		
		public static func convertFromExtendedGraphemeClusterLiteral(value: String) -> Identifier {
			return	Identifier(name: value)
		}
	}
	
	public enum ColumnList : QueryExpressible {
		case All
		case Items(names:[Identifier])
		
		public func express() -> Query.Expression {
			switch self {
			case let All:
				return	Expression(code: "*", parameters: [])
				
			case let Items(names: names):
				return	Expression.concatenation(separator: Query.Expression.empty, components: names.map {$0.express()})
			}
		}
	}
	
	///	Only for value setting expression.
	public struct Binding : QueryExpressible {
		public let	column:Identifier
		public let	value:ParameterValueEvaluation
		
		///	Makes `col1 = @param1` style expression.
		public func express() -> Query.Expression {
			return	column.express()
				+	"="
				+	Expression(code: "?", parameters: [value])
		}
	}
//	public struct BindingList : SubqueryExpressible
//	{
//		public let	items:[Binding]
//		
//		func express(uniqueParameterNameGenerator upng: Query.UniqueParameterNameGenerator) -> Query.Expression
//		{
//			return	Expression.expressionize(using: upng)(elements: items).concatenation()
//		}
//	}
	
	public struct FilterTree : QueryExpressible {
		public let	root:Node
		
		public func express() -> Query.Expression {
			return	root.express()
		}
		
		public enum Node : QueryExpressible {
			public enum Operation : QueryExpressible {
				case Equal
				case NotEqual
				case LessThan
				case GreaterThan
				case EqualOrLessThan
				case EqualOrGreaterThan
//				case Between
//				case Like
//				case In
				
				public func express() -> Query.Expression {
					switch self {
						case .Equal:				return	Expression(code: "=", parameters: [])
						case .NotEqual:				return	Expression(code: "<>", parameters: [])
						case .LessThan:				return	Expression(code: "<", parameters: [])
						case .GreaterThan:			return	Expression(code: ">", parameters: [])
						case .EqualOrLessThan:		return	Expression(code: "<=", parameters: [])
						case .EqualOrGreaterThan:	return	Expression(code: ">=", parameters: [])
					}
				}
			}

			public enum Combination : QueryExpressible {
				case And
				case Or
				
				public func express() -> Query.Expression {
					switch self {
						case .And:	return	Expression(code: "AND", parameters: [])
						case .Or:	return	Expression(code: "OR", parameters: [])
					}
				}
			}
			
			case Leaf(operation:Operation, column:Identifier, value:Query.ParameterValueEvaluation)
			case Branch(combination:Combination, subnodes:[Node])
			
			public func express() -> Query.Expression {
				switch self {
				case let Leaf(operation: op, column: col, value: val):
					return	col.express()
					+		op.express()
					+		Expression(code: "?", parameters: [val])
				
				case let Branch(combination: comb, subnodes: ns):
					let	x1	=	" " + comb.express() + " "
					return	Expression.concatenation(separator: x1, components: ns.map {$0.express()})
				}
			}
		}
		
	}
	
	
	
	
	
	
	
		
}



package org.osflash.spod.builders.table
{
	import org.osflash.spod.SpodObject;
	import org.osflash.spod.SpodStatement;
	import org.osflash.spod.builders.ISpodStatementBuilder;
	import org.osflash.spod.schema.ISpodColumnSchema;
	import org.osflash.spod.schema.ISpodSchema;
	import org.osflash.spod.schema.SpodTableSchema;
	import org.osflash.spod.schema.types.SpodSchemaType;
	import org.osflash.spod.types.SpodTypes;
	import org.osflash.spod.utils.getIdentifierValueFromObject;

	import flash.errors.IllegalOperationError;
	import flash.utils.getQualifiedClassName;

	/**
	 * @author Simon Richardson - me@simonrichardson.info
	 */
	public class UpdateStatementBuilder implements ISpodStatementBuilder
	{

		/**
		 * @private
		 */
		private var _schema : ISpodSchema;
		
		/**
		 * @private
		 */
		private var _object : SpodObject;

		/**
		 * @private
		 */
		private var _buffer : Vector.<String>;

		public function UpdateStatementBuilder(schema : ISpodSchema, object : SpodObject)
		{
			if(null == schema) throw new ArgumentError('Schema can not be null');
			if(null == object) throw new ArgumentError('Object can not be null');
			if(schema.schemaType != SpodSchemaType.TABLE) throw new ArgumentError('Schema ' + 
																		'should be a table schema');
			_schema = schema;
			_object = object;
			
			_buffer = new Vector.<String>();
		}

		public function build() : SpodStatement
		{
			if(_schema is SpodTableSchema)
			{
				const tableSchema : SpodTableSchema = SpodTableSchema(_schema);
				const columns : Vector.<ISpodColumnSchema> = tableSchema.columns;
				const total : int = columns.length;
				
				if(total == 0) throw new IllegalOperationError('Invalid columns length');
				
				_buffer.length = 0;
				
				_buffer.push('UPDATE ');
				_buffer.push('`' + _schema.name + '` ');
				
				var i : int;
				var column : ISpodColumnSchema;
				var customName : Boolean;
				var columnName : String;
				
				const customColumnNames : Boolean = tableSchema.customColumnNames;
				const statementType : Class = customColumnNames ? Object : tableSchema.type;
				const statement : SpodStatement = new SpodStatement(statementType, _object);
				
				// Get the names
				_buffer.push('SET ');
				for(i=0; i<total; i++)
				{
					column = columns[i];
					customName = column.customColumnName;
					columnName = customName ? column.alternativeName : column.name;
					
					if(	columnName == _schema.identifier && 
						column.type == SpodTypes.INT &&
						column.autoIncrement
						) 
						continue;
					
					_buffer.push('`' + columnName + '`');
					_buffer.push('=');
					
					_buffer.push(':' + columnName + '');
					_buffer.push(', ');
						
					statement.parameters[':' + columnName] = _object[column.name];
				}
				_buffer.pop();
				
				_buffer.push(' WHERE ');
				_buffer.push('`' + _schema.identifier + '`=:id');
				
				const identifierColumn : ISpodColumnSchema = tableSchema.getColumnByName(
																				_schema.identifier);
				const identifierName : String = identifierColumn.name;
				
				statement.parameters[':id'] = getIdentifierValueFromObject(	_object, 
																			identifierName
																			);
				
				// Make the query
				statement.query = _buffer.join('');
				
				return statement;
				
			} else throw new ArgumentError(getQualifiedClassName(_schema) + ' is not supported');
		}
	}
}

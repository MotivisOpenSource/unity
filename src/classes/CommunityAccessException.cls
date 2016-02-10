/* 
 * Unity - Communities
 * 
 * Community is critical to the student experience--but building community is 
 * just plain hard. Built on Communities and designed specifically for higher ed, 
 * Unity is a powerful networking tool to help you generate engagement and 
 * connect your campus.
 * 
 * Copyright (C) 2015 Motivis Learning Systems Inc.
 * 
 * This program is free software: you can redistribute it and/or modify 
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 * 
 * To contact Motivis Learning Systems Inc.
 * 25 Pelham Road
 * Salem, NH 03790
 * unity@motivislearning.com
 */
global with sharing class CommunityAccessException extends Exception {
	// ExceptionType - this enum defines the different types of access control exceptions.
	global enum ExceptionType {
		// This error is a generic error type.
		GENERIC,
		// This error type is an object level access violation.
		OBJECT_ACCESS_VIOLATION,
		// This error type is a field level access violation.
		FIELD_ACCESS_VIOLATION,
		// This error type is a sharing access violation.
		SHARING_ACCESS_VIOLATION,
		// This error type is a generic record not found error. This can be due to record does not exist, sharing violation, or other errors.
		NO_RECORD_FOUND
	}

	// ExceptionReason - this enum defines the different reasons for the exception type.
	global enum ExceptionReason {
		// This is a generic reason.
		GENERIC,
		// This error is due to the user not having the create permission on the specific object/field/record.
		NO_CREATE,
		// This error is due to the user not having the read permission on the specific object/field/record.
		NO_READ,
		// This error is due to the user not having the update permission on the specific object/field/record.
		NO_UPDATE,
		// This error is due to the user not having the delete permission on the specific object/field/record.
		NO_DELETE
	}

	private ExceptionType eType;
	private ExceptionReason eReason;
	private String eObject;
	private String eField;
	private String eText;

	public String ExceptionMessage {
		get {
			return eText + ' : ' + eType + ' - ' + eReason + ' : ' + eObject + '.' + eField;
		}
	}

	/*
	 * Constructor for CommunityAccessException.
	 * @param eText Error text
	 * @param eType ExceptionType for this error
	 * @param eReason ExceptionReason for this error
	 * @param eObject The object name this error was triggered on
	 * @param eField The field name this error was triggered on
	 */
	global CommunityAccessException(String eText, ExceptionType eType, ExceptionReason eReason, String eObject, String eField) {
		this.eText = eText;
		this.eType = eType;
		this.eReason = eReason;
		this.eObject = eObject;
		this.eField = eField;
		this.setMessage(this.ExceptionMessage);
		System.Debug(Logginglevel.ERROR, 'CommunityAccessException: ' + ExceptionMessage + ' - ' + this.getStackTraceString());
	}

	// Get the exception type - Object Access Violation, Field Access Violation, etc.
	// You might not want to expose the details of the exception to the users.
	global ExceptionType getExceptionType() {
		return this.eType;
	}

	// Get the exception reason - no create, no update, etc.
	// You might not want to expose the details of the exception to the users.
	global ExceptionReason getExceptionReason() {
		return this.eReason;
	}

	// Get the object on which the exception occurred.
	// You might not want to expose the details of the exception to the users.
	global String getExceptionObject() {
		return this.eObject;
	}

	// Get the field on which the exception occurred.
	// You might not want to expose the details of the exception to the users.
	global String getExceptionField() {
		return this.eField;
	}

	// Get the error text.
	// You might not want to expose the details of the exception to the users.
	global String getText() {
		return this.eText;
	}
}
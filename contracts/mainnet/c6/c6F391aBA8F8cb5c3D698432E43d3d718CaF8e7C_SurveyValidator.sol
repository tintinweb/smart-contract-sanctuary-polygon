// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "@openzeppelin/contracts//security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/ISurveyValidator.sol";
import {StringUtils} from "../libraries/StringUtils.sol";
import {IntUtils} from "../libraries/IntUtils.sol";

contract SurveyValidator is ISurveyValidator, Ownable, ReentrancyGuard {

    using StringUtils for *;
    using IntUtils for *;

    uint256 public tknSymbolMaxLength = 64;
    uint256 public tknNameMaxLength = 128;
    uint256 public titleMaxLength = 128;
    uint256 public descriptionMaxLength = 512;
    uint256 public urlMaxLength = 2048;
    uint256 public startMaxTime = 864000;// maximum time to start the survey (10 days)
    uint256 public rangeMinTime = 86399;// minimum duration time (0d 23:59:59)
    uint256 public rangeMaxTime = 2591999;// maximum duration time (29d 23:59:59)
    uint256 public questionMaxPerSurvey = 100;
    uint256 public questionMaxLength = 4096;
    uint256 public validatorMaxPerQuestion = 10;
    uint256 public validatorValueMaxLength = 128;
    uint256 public hashMaxPerSurvey = 1000;
    uint256 public responseMaxLength = 2048;

    // ### Validation functions ###

    function checkSurvey(SurveyRequest memory survey, Question[] memory questions, Validator[] memory validators, string[] memory hashes) 
    external override nonReentrant {
        // Validate token metadata
        try IERC20Metadata(survey.token).symbol() returns (string memory symbol) {
            uint256 symbolLength = symbol.toSlice().len();
            require(symbolLength == symbol.trim().toSlice().len(), "SurveyValidator: token symbol with leading or trailing spaces");
            require(symbolLength > 0, "SurveyValidator: empty token symbol");
            require(symbolLength <= tknSymbolMaxLength, "SurveyValidator: invalid token symbol");
        } catch {
            revert("SurveyValidator: no token symbol");
        }

        try IERC20Metadata(survey.token).name() returns (string memory name) {
            uint256 nameLength = name.toSlice().len();
            require(nameLength == name.trim().toSlice().len(), "SurveyValidator: token name with leading or trailing spaces");
            require(nameLength > 0, "SurveyValidator: empty token name");
            require(nameLength <= tknNameMaxLength, "SurveyValidator: invalid token name");
        } catch {
            revert("SurveyValidator: no token name");
        }
        
        // Validate title
        uint256 titleLength = survey.title.toSlice().len();
        require(titleLength == survey.title.trim().toSlice().len(), "SurveyValidator: title with leading or trailing spaces");
        require(titleLength > 0, "SurveyValidator: no survey title");
        require(titleLength <= titleMaxLength, "SurveyValidator: very long survey title");

        // Validate description
        uint256 descLength = survey.description.toSlice().len();
        require(descLength == survey.description.trim().toSlice().len(), "SurveyValidator: description with leading or trailing spaces");
        require(descLength <= descriptionMaxLength, "SurveyValidator: very long survey description");

        // Validate logo URL
        StringUtils.slice memory logoUrlSlice = survey.logoUrl.toSlice();
        uint256 logoUrlLength = logoUrlSlice.len();
        require(logoUrlLength == survey.logoUrl.trim().toSlice().len(), "SurveyValidator: logo URL with leading or trailing spaces");
        require(logoUrlLength <= urlMaxLength, "SurveyValidator: very long survey logo URL");
        if(logoUrlLength > 0) {
            require(logoUrlSlice.startsWith("http://".toSlice()) || logoUrlSlice.startsWith("https://".toSlice()) || logoUrlSlice.startsWith("ipfs://".toSlice()), 
            "SurveyValidator: invalid logo URL");
        }

        // Validate date range
        require(survey.startTime >= block.timestamp && survey.startTime < survey.endTime, "SurveyValidator: invalid date range");
        require(survey.startTime <= block.timestamp + startMaxTime, "SurveyValidator: distant start date");
        require(survey.endTime - survey.startTime - 1 >= rangeMinTime, "SurveyValidator: date range too small");
        require(survey.endTime - survey.startTime - 1 <= rangeMaxTime, "SurveyValidator: date range too large");

        // Validate budget
        require(survey.budget > 0, "SurveyValidator: budget is zero");

        // Validate reward
        require(survey.reward > 0, "SurveyValidator: reward is zero");
        require(survey.reward <= survey.budget, "SurveyValidator: reward exceeds budget");

        // Validate participations number
        require(survey.budget%survey.reward == 0, "SurveyValidator: incorrect number of participations");
        
        // Validate number of questions
        require(questions.length > 0, "SurveyValidator: no questions");
        require(questions.length <= questionMaxPerSurvey, "SurveyValidator: exceeded number of questions");

        // Check hashes
        uint256 partsNum = survey.budget / survey.reward;
        require(hashes.length == 0 || (hashes.length == partsNum && hashes.length <= hashMaxPerSurvey), "SurveyValidator: incorrect number of hashes");

        for(uint i = 0; i < hashes.length; i++) {
            require(bytes(hashes[i]).length == 8, "SurveyValidator: invalid hash");
        }

        uint256 validatorsTotal = 0;

        // Check questions
        for(uint i = 0; i < questions.length; i++) {
            uint256 count = 0;
            for(uint j = 0; j < validators.length; j++) {
                if(validators[j].questionIndex == i) {
                    count++;
                }
            }

            require(count <= validatorMaxPerQuestion, "SurveyValidator: exceeded number of validators per question");
            _checkQuestion(questions[i]);
            validatorsTotal += count;
        }
        
        // Check validators
        require(validators.length == validatorsTotal, "SurveyValidator: incorrect number of validators");

        for(uint i = 0; i < validators.length; i++) {
            _checkValidator(questions[validators[i].questionIndex], validators[i]);
        }
    }

    function checkResponse(Question memory question, Validator[] memory validators, string memory response) external view override {
        uint256 responseLength = response.toSlice().len();

        if(responseLength == 0) {
            require(!question.mandatory, "SurveyValidator: mandatory response empty");
			return;
        }

        require(responseLength == response.trim().toSlice().len(), "SurveyValidator: response with leading or trailing spaces");
        require(responseLength <= responseMaxLength, "SurveyValidator: response too long");
        require(_checkResponseType(question.responseType, response), "SurveyValidator: invalid response type");
        
        // Apply validators, there can be multiple values, each value must pass the validators.
        string[] memory values = _parseResponse(question.responseType, response);

        for(uint i = 0; i < values.length; i++) {
            require(values[i].toSlice().len() == values[i].trim().toSlice().len(), "SurveyValidator: value with leading or trailing spaces");
            bool valid = true;

            for(uint j = 0; j < validators.length; j++) {
               if(j == 0) {
                   valid = _checkExpression(validators[j], values[i]);
               } else if(validators[j - 1].operator == Operator.Or) {
                    valid = valid || _checkExpression(validators[j], values[i]);
                } else {// operator == None or And
                    valid = valid && _checkExpression(validators[j], values[i]);
                }
            }

            require(valid, "SurveyValidator: invalid response");
        }
    }

    function isLimited(ResponseType responseType) external pure override returns (bool) {
        return _isLimited(responseType);
    }

    function isArray(ResponseType responseType) external pure override returns (bool) {
        return _isArray(responseType);
    }

    // ### Owner functions ###

    function setTknSymbolMaxLength(uint256 _tknSymbolMaxLength) external override onlyOwner {
        tknSymbolMaxLength = _tknSymbolMaxLength;
    }

    function setTknNameMaxLength(uint256 _tknNameMaxLength) external override onlyOwner {
        tknNameMaxLength = _tknNameMaxLength;
    }

    function setTitleMaxLength(uint256 _titleMaxLength) external override onlyOwner {
        titleMaxLength = _titleMaxLength;
    }

    function setDescriptionMaxLength(uint256 _descriptionMaxLength) external override onlyOwner {
        descriptionMaxLength = _descriptionMaxLength;
    }

    function setUrlMaxLength(uint256 _urlMaxLength) external override onlyOwner {
        urlMaxLength = _urlMaxLength;
    }

    function setStartMaxTime(uint256 _startMaxTime) external override onlyOwner {
        startMaxTime = _startMaxTime;
    }

    function setRangeMinTime(uint256 _rangeMinTime) external override onlyOwner {
        rangeMinTime = _rangeMinTime;
    }

    function setRangeMaxTime(uint256 _rangeMaxTime) external override onlyOwner {
        rangeMaxTime = _rangeMaxTime;
    }

    function setQuestionMaxPerSurvey(uint256 _questionMaxPerSurvey) external override onlyOwner {
        questionMaxPerSurvey = _questionMaxPerSurvey;
    }

    function setQuestionMaxLength(uint256 _questionMaxLength) external override onlyOwner {
        questionMaxLength = _questionMaxLength;
    }

    function setValidatorMaxPerQuestion(uint256 _validatorMaxPerQuestion) external override onlyOwner {
        validatorMaxPerQuestion = _validatorMaxPerQuestion;
    }

    function setValidatorValueMaxLength(uint256 _validatorValueMaxLength) external override onlyOwner {
        validatorValueMaxLength = _validatorValueMaxLength;
    }

    function setHashMaxPerSurvey(uint256 _hashMaxPerSurvey) external override onlyOwner {
        hashMaxPerSurvey = _hashMaxPerSurvey;
    }

    function setResponseMaxLength(uint256 _responseMaxLength) external override onlyOwner {
        responseMaxLength = _responseMaxLength;
    }

    // ### Internal functions ###

    function _checkQuestion(Question memory question) internal view {
        uint256 contentLength = question.content.toSlice().len();
        require(contentLength == question.content.trim().toSlice().len(), "SurveyValidator: question content with leading or trailing spaces");
        require(contentLength > 0, "SurveyValidator: unspecified question content");
        require(contentLength <= questionMaxLength, "SurveyValidator: very long question content");
    }

    function _checkValidator(Question memory question, Validator memory validator) internal view {
        uint256 validatorValueLength = validator.value.toSlice().len();

        if(validator.expression != Expression.Empty && validator.expression != Expression.NotEmpty && 
           validator.expression != Expression.ContainsDigits && validator.expression != Expression.NotContainsDigits) {
                require(validatorValueLength == validator.value.trim().toSlice().len(), "SurveyValidator: validator value with leading or trailing spaces");
                require(validatorValueLength > 0 && validatorValueLength <= validatorValueMaxLength, "SurveyValidator: invalid validator value");

                if(validator.expression == Expression.Greater || validator.expression == Expression.GreaterEquals || 
                   validator.expression == Expression.Less || validator.expression == Expression.LessEquals || 
                   question.responseType == ResponseType.Number || question.responseType == ResponseType.ArrayNumber || 
                   question.responseType == ResponseType.Range) {
                      require(validator.value.isDigit(), "SurveyValidator: validator value must be an integer");
                }
                
                if(validator.expression == Expression.MinLength || validator.expression == Expression.MaxLength || 
                   question.responseType == ResponseType.Percent || question.responseType == ResponseType.Rating || 
                   question.responseType == ResponseType.Date || question.responseType == ResponseType.DateRange || 
                   question.responseType == ResponseType.ArrayDate) {
                      require(validator.value.isUDigit(), "SurveyValidator: validator value must be a positive integer");
                }

                if(validator.expression == Expression.MinLength || validator.expression == Expression.MaxLength) {
                    require(validator.value.parseUInt() <= responseMaxLength, "SurveyValidator: validator value exceeds response limit");
                }
                
                if(question.responseType == ResponseType.Bool || question.responseType == ResponseType.ArrayBool) {
                    require(validator.value.toSlice().equals("true".toSlice()) || validator.value.toSlice().equals("false".toSlice()), 
                    "SurveyValidator: validator value must be a boolean");
                }
        } else {
            require(validatorValueLength == 0, "SurveyValidator: the validator does not require any value");
        }
    }

    function _parseResponse(ResponseType responseType, string memory response) internal pure returns (string[] memory) {
        string[] memory values;

        if(_isArray(responseType)) {
            values = response.split(";");
        } else {
            values = new string[](1);
            values[0] = response;
        }

        return values;
    }

    function _isLimited(ResponseType responseType) internal pure returns (bool) {
        return responseType == ResponseType.Bool || 
        responseType == ResponseType.Percent || 
        responseType == ResponseType.Rating || 
        responseType == ResponseType.OneOption || 
        responseType == ResponseType.ManyOptions || 
        responseType == ResponseType.ArrayBool;
    }

    function _isArray(ResponseType responseType) internal pure returns (bool) {
        return responseType == ResponseType.ManyOptions || 
        responseType == ResponseType.Range || 
        responseType == ResponseType.DateRange || 
        responseType == ResponseType.ArrayBool || 
        responseType == ResponseType.ArrayText || 
        responseType == ResponseType.ArrayNumber || 
        responseType == ResponseType.ArrayDate;
    }

    function _checkResponseType(ResponseType responseType, string memory value) internal pure returns (bool) {
        if(responseType == ResponseType.Bool) {
            return value.toSlice().equals("true".toSlice()) || value.toSlice().equals("false".toSlice());
        } else if(responseType == ResponseType.Text) {
            return true;
        } else if(responseType == ResponseType.Number) {
            return value.isDigit();
        } else if(responseType == ResponseType.Percent) {
            if(!value.isUDigit()) {
                return false;
            }
			
			uint256 num = value.parseUInt();
            return num > 0 && num <= 100;
        } else if(responseType == ResponseType.Date) {
            return value.isUDigit();
        } else if(responseType == ResponseType.Rating) {
            if(!value.isUDigit()) {
                return false;
            }

            uint256 num = value.parseUInt();
            return num > 0 && num <= 5;
        } else if(responseType == ResponseType.OneOption) {
            if(!value.isUDigit()) {
                return false;
            }

            return value.parseUInt() <= 100;
        } else if(responseType == ResponseType.ManyOptions) {
            string[] memory array = value.split(";");
            for(uint i = 0; i < array.length; i++) {
                if(!_checkResponseType(ResponseType.OneOption, array[i])) {
                    return false;
                }
            }

            return true;
        } else if(responseType == ResponseType.Range) {
            string[] memory array = value.split(";");
            if(array.length != 2) {
                return false;
            }

            for(uint i = 0; i < array.length; i++) {
                if(!array[i].isDigit()) {
                    return false;
                }

                if(i == 1 && array[i].parseInt() <= array[i-1].parseInt()) {
                    return false;
                }
            }

            return true;
        } else if(responseType == ResponseType.DateRange) {
            string[] memory array = value.split(";");
            if(array.length != 2) {
                return false;
            }

            for(uint i = 0; i < array.length; i++) {
                if(!array[i].isUDigit()) {
                    return false;
                }

                if(i == 1 && array[i].parseUInt() <= array[i-1].parseUInt()) {
                    return false;
                }
            }

            return true;
        } else if(responseType == ResponseType.ArrayBool) {
            string[] memory array = value.split(";");
            for(uint i = 0; i < array.length; i++) {
                if(!_checkResponseType(ResponseType.Bool, array[i])) {
                    return false;
                }
            }

            return true;
        } else if(responseType == ResponseType.ArrayText) {
            string[] memory array = value.split(";");
            for(uint i = 0; i < array.length; i++) {
                if(!_checkResponseType(ResponseType.Text, array[i])) {
                    return false;
                }
            }

            return true;
        } else if(responseType == ResponseType.ArrayNumber) {
            string[] memory array = value.split(";");
            for(uint i = 0; i < array.length; i++) {
                if(!_checkResponseType(ResponseType.Number, array[i])) {
                    return false;
                }
            }

            return true;
        } else if(responseType == ResponseType.ArrayDate) {
            string[] memory array = value.split(";");
            for(uint i = 0; i < array.length; i++) {
                if(!_checkResponseType(ResponseType.Date, array[i])) {
                    return false;
                }
            }

            return true;
        }

        revert("Unknown response type.");
    }

    function _checkExpression(Validator memory validator, string memory value) internal pure returns (bool) {
        if(validator.expression == Expression.Empty) {
            return value.toSlice().empty();
        } else if(validator.expression == Expression.NotEmpty) {
            return !value.toSlice().empty();
        } else if(validator.expression == Expression.Equals) {
            return value.toSlice().equals(validator.value.toSlice());
        } else if(validator.expression == Expression.NotEquals) {
            return !value.toSlice().equals(validator.value.toSlice());
        } else if(validator.expression == Expression.Contains) {
            return value.toSlice().contains(validator.value.toSlice());
        } else if(validator.expression == Expression.NotContains) {
            return !value.toSlice().contains(validator.value.toSlice());
        } else if(validator.expression == Expression.EqualsIgnoreCase) {
            return value.equalsIgnoreCase(validator.value);
        } else if(validator.expression == Expression.NotEqualsIgnoreCase) {
            return !value.equalsIgnoreCase(validator.value);
        } else if(validator.expression == Expression.ContainsIgnoreCase) {
            return value.containsIgnoreCase(validator.value);
        } else if(validator.expression == Expression.NotContainsIgnoreCase) {
            return !value.containsIgnoreCase(validator.value);
        } else if(validator.expression == Expression.Greater) {
            return value.parseInt() > validator.value.parseInt();
        } else if(validator.expression == Expression.GreaterEquals) {
            return value.parseInt() >= validator.value.parseInt();
        } else if(validator.expression == Expression.Less) {
            return value.parseInt() < validator.value.parseInt();
        } else if(validator.expression == Expression.LessEquals) {
            return value.parseInt() <= validator.value.parseInt();
        } else if(validator.expression == Expression.ContainsDigits) {
            return value.containsDigits();
        } else if(validator.expression == Expression.NotContainsDigits) {
            return !value.containsDigits();
        } else if(validator.expression == Expression.MinLength) {
            return value.toSlice().len() >= validator.value.parseUInt();
        } else if(validator.expression == Expression.MaxLength) {
            return value.toSlice().len() <= validator.value.parseUInt();
        }

        revert("Unknown expression.");
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import "./ISurveyModel.sol";

/**
 * @dev Interface to implement a survey validation contract
 */
interface ISurveyValidator is ISurveyModel {

    // ### Validation functions ###

    function checkSurvey(SurveyRequest memory survey, Question[] memory questions, Validator[] memory validators, string[] memory hashes) external;
    function checkResponse(Question memory question, Validator[] memory validators, string memory response) external;
    function isLimited(ResponseType responseType) external returns (bool);
    function isArray(ResponseType responseType) external returns (bool);

    // ### Owner functions `onlyOwner` ###

    function setTknSymbolMaxLength(uint256 tknSymbolMaxLength) external;
    function setTknNameMaxLength(uint256 tknNameMaxLength) external;
    function setTitleMaxLength(uint256 titleMaxLength) external;
    function setDescriptionMaxLength(uint256 descriptionMaxLength) external;
    function setUrlMaxLength(uint256 urlMaxLength) external;
    function setStartMaxTime(uint256 startMaxTime) external;
    function setRangeMinTime(uint256 rangeMinTime) external;
    function setRangeMaxTime(uint256 rangeMaxTime) external;
    function setQuestionMaxPerSurvey(uint256 questionMaxPerSurvey) external;
    function setQuestionMaxLength(uint256 questionMaxLength) external;
    function setValidatorMaxPerQuestion(uint256 validatorMaxPerQuestion) external;
    function setValidatorValueMaxLength(uint256 validatorValueMaxLength) external;
    function setHashMaxPerSurvey(uint256 hashMaxPerSurvey) external;
    function setResponseMaxLength(uint256 responseMaxLength) external;
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

/**
 * @dev Interface containing the survey structure
 */
interface ISurveyModel {

    // ArrayText elements should not contain the separator (;)
    enum ResponseType {
        Bool, Text, Number, Percent, Date, Rating, OneOption, 
        ManyOptions, Range, DateRange,
        ArrayBool, ArrayText, ArrayNumber, ArrayDate
    }

    struct Question {
        string content;// json that represents the content of the question
        bool mandatory;
        ResponseType responseType;
    }

    struct SurveyRequest {
        string title;
        string description;
        string logoUrl;
        uint256 startTime;
        uint256 endTime;
        uint256 budget;// Total budget of INC tokens
        uint256 reward;// Reward amount for participation
        address token;// Incentive token
    }

    struct SurveyWrapper {
        address account;
        SurveyRequest survey;
        Question[] questions;
        Validator[] validators;
        string[] hashes;
        uint256 gasReserve;
    }

    struct Survey {
        string title;
        string description;
        string logoUrl;
        uint256 startTime;
        uint256 endTime;
        uint256 budget;
        uint256 reward;
        address token;
        bool keyRequired;
        uint256 surveyTime;
        address surveyOwner;
        address surveyAddr;
    }

    struct Participation {
        address surveyAddr;
        string[] responses;
        uint256 txGas;
        uint256 gasPrice;
        uint256 partTime;
        address partOwner;
    }

    enum Operator {
        None, And, Or
    }

    enum Expression {
        None,
        Empty,
        NotEmpty,
        Equals,
        NotEquals,
        Contains,
        NotContains,
        EqualsIgnoreCase,
        NotEqualsIgnoreCase,
        ContainsIgnoreCase,
        NotContainsIgnoreCase,
        Greater,
        GreaterEquals,
        Less,
        LessEquals,
        ContainsDigits,
        NotContainsDigits,
        MinLength,
        MaxLength
    }

    struct Validator {
        uint256 questionIndex;
        Operator operator;
        Expression expression;
        string value;
    }

    struct ResponseCount {
        string value;
        uint256 count;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/*
 * Strings Library
 *
 * Functionality in this library is largely implemented using an
 * abstraction called a 'slice'. A slice represents a part of a string -
 * anything from the entire string to a single character, or even no
 * characters at all (a 0-length slice). Since a slice only has to specify
 * an offset and a length, copying and manipulating slices is a lot less
 * expensive than copying and manipulating the strings they reference.
 *
 * To further reduce gas costs, most functions on slice that need to return
 * a slice modify the original one instead of allocating a new one; for
 * instance, `s.split(".")` will return the text up to the first '.',
 * modifying s to only contain the remainder of the string after the '.'.
 * In situations where you do not want to modify the original slice, you
 * can make a copy first with `.copy()`, for example:
 * `s.copy().split(".")`. Try and avoid using this idiom in loops; since
 * Solidity has no memory management, it will result in allocating many
 * short-lived slices that are later discarded.
 *
 * Functions that return two slices come in two versions: a non-allocating
 * version that takes the second slice as an argument, modifying it in
 * place, and an allocating version that allocates and returns the second
 * slice; see `nextRune` for example.
 *
 * Functions that have to copy string data will return strings rather than
 * slices; these can be cast back to slices for further processing if
 * required.
 *
 * For convenience, some functions are provided with non-modifying
 * variants that create a new slice and return both; for instance,
 * `s.splitNew('.')` leaves s unmodified, and returns two values
 * corresponding to the left and right parts of the string.
 */
library StringUtils {

    struct slice {
        uint _len;
        uint _ptr;
    }

    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    function memcpy(uint dest, uint src, uint _len) private pure {
        // Copy word-length chunks while possible
        for(; _len >= 32; _len -= 32) {
            assembly {
                mstore(dest, mload(src))
            }
            dest += 32;
            src += 32;
        }

        // Copy remaining bytes
        uint mask = type(uint).max;
        if (_len > 0) {
            mask = 256 ** (32 - _len) - 1;
        }
        assembly {
            let srcpart := and(mload(src), not(mask))
            let destpart := and(mload(dest), mask)
            mstore(dest, or(destpart, srcpart))
        }
    }

    /*
     * @dev Returns a slice containing the entire string.
     * @param self The string to make a slice from.
     * @return A newly allocated slice containing the entire string.
     */
    function toSlice(string memory self) internal pure returns (slice memory) {
        uint ptr;
        assembly {
            ptr := add(self, 0x20)
        }
        return slice(bytes(self).length, ptr);
    }

    /*
     * @dev Returns the length of a null-terminated bytes32 string.
     * @param self The value to find the length of.
     * @return The length of the string, from 0 to 32.
     */
    function len(bytes32 self) internal pure returns (uint) {
        uint ret;
        if (self == 0)
            return 0;
        if (uint(self) & type(uint128).max == 0) {
            ret += 16;
            self = bytes32(uint(self) / 0x100000000000000000000000000000000);
        }
        if (uint(self) & type(uint64).max == 0) {
            ret += 8;
            self = bytes32(uint(self) / 0x10000000000000000);
        }
        if (uint(self) & type(uint32).max == 0) {
            ret += 4;
            self = bytes32(uint(self) / 0x100000000);
        }
        if (uint(self) & type(uint16).max == 0) {
            ret += 2;
            self = bytes32(uint(self) / 0x10000);
        }
        if (uint(self) & type(uint8).max == 0) {
            ret += 1;
        }
        return 32 - ret;
    }

    /*
     * @dev Returns a slice containing the entire bytes32, interpreted as a
     *      null-terminated utf-8 string.
     * @param self The bytes32 value to convert to a slice.
     * @return A new slice containing the value of the input argument up to the
     *         first null.
     */
    function toSliceB32(bytes32 self) internal pure returns (slice memory ret) {
        // Allocate space for `self` in memory, copy it there, and point ret at it
        assembly {
            let ptr := mload(0x40)
            mstore(0x40, add(ptr, 0x20))
            mstore(ptr, self)
            mstore(add(ret, 0x20), ptr)
        }
        ret._len = len(self);
    }

    /*
     * @dev Returns a new slice containing the same data as the current slice.
     * @param self The slice to copy.
     * @return A new slice containing the same data as `self`.
     */
    function copy(slice memory self) internal pure returns (slice memory) {
        return slice(self._len, self._ptr);
    }

    /*
     * @dev Copies a slice to a new string.
     * @param self The slice to copy.
     * @return A newly allocated string containing the slice's text.
     */
    function toString(slice memory self) internal pure returns (string memory) {
        string memory ret = new string(self._len);
        uint retptr;
        assembly { retptr := add(ret, 32) }

        memcpy(retptr, self._ptr, self._len);
        return ret;
    }

    /*
     * @dev Returns the length in runes of the slice. Note that this operation
     *      takes time proportional to the length of the slice; avoid using it
     *      in loops, and call `slice.empty()` if you only need to know whether
     *      the slice is empty or not.
     * @param self The slice to operate on.
     * @return The length of the slice in runes.
     */
    function len(slice memory self) internal pure returns (uint l) {
        // Starting at ptr-31 means the LSB will be the byte we care about
        uint ptr = self._ptr - 31;
        uint end = ptr + self._len;
        for (l = 0; ptr < end; l++) {
            uint8 b;
            assembly { b := and(mload(ptr), 0xFF) }
            if (b < 0x80) {
                ptr += 1;
            } else if(b < 0xE0) {
                ptr += 2;
            } else if(b < 0xF0) {
                ptr += 3;
            } else if(b < 0xF8) {
                ptr += 4;
            } else if(b < 0xFC) {
                ptr += 5;
            } else {
                ptr += 6;
            }
        }
    }

    /*
     * @dev Returns true if the slice is empty (has a length of 0).
     * @param self The slice to operate on.
     * @return True if the slice is empty, False otherwise.
     */
    function empty(slice memory self) internal pure returns (bool) {
        return self._len == 0;
    }

    /*
     * @dev Returns a positive number if `other` comes lexicographically after
     *      `self`, a negative number if it comes before, or zero if the
     *      contents of the two slices are equal. Comparison is done per-rune,
     *      on unicode codepoints.
     * @param self The first slice to compare.
     * @param other The second slice to compare.
     * @return The result of the comparison.
     */
    function compare(slice memory self, slice memory other) internal pure returns (int) {
        uint shortest = self._len;
        if (other._len < self._len)
            shortest = other._len;

        uint selfptr = self._ptr;
        uint otherptr = other._ptr;
        for (uint idx = 0; idx < shortest; idx += 32) {
            uint a;
            uint b;
            assembly {
                a := mload(selfptr)
                b := mload(otherptr)
            }
            if (a != b) {
                // Mask out irrelevant bytes and check again
                uint mask = type(uint).max; // 0xffff...
                if(shortest < 32) {
                  mask = ~(2 ** (8 * (32 - shortest + idx)) - 1);
                }
                unchecked {
                    uint diff = (a & mask) - (b & mask);
                    if (diff != 0)
                        return int(diff);
                }
            }
            selfptr += 32;
            otherptr += 32;
        }
        return int(self._len) - int(other._len);
    }

    /*
     * @dev Returns true if the two slices contain the same text.
     * @param self The first slice to compare.
     * @param self The second slice to compare.
     * @return True if the slices are equal, false otherwise.
     */
    function equals(slice memory self, slice memory other) internal pure returns (bool) {
        return compare(self, other) == 0;
    }

    /*
     * @dev Extracts the first rune in the slice into `rune`, advancing the
     *      slice to point to the next rune and returning `self`.
     * @param self The slice to operate on.
     * @param rune The slice that will contain the first rune.
     * @return `rune`.
     */
    function nextRune(slice memory self, slice memory rune) internal pure returns (slice memory) {
        rune._ptr = self._ptr;

        if (self._len == 0) {
            rune._len = 0;
            return rune;
        }

        uint l;
        uint b;
        // Load the first byte of the rune into the LSBs of b
        assembly { b := and(mload(sub(mload(add(self, 32)), 31)), 0xFF) }
        if (b < 0x80) {
            l = 1;
        } else if(b < 0xE0) {
            l = 2;
        } else if(b < 0xF0) {
            l = 3;
        } else {
            l = 4;
        }

        // Check for truncated codepoints
        if (l > self._len) {
            rune._len = self._len;
            self._ptr += self._len;
            self._len = 0;
            return rune;
        }

        self._ptr += l;
        self._len -= l;
        rune._len = l;
        return rune;
    }

    /*
     * @dev Returns the first rune in the slice, advancing the slice to point
     *      to the next rune.
     * @param self The slice to operate on.
     * @return A slice containing only the first rune from `self`.
     */
    function nextRune(slice memory self) internal pure returns (slice memory ret) {
        nextRune(self, ret);
    }

    /*
     * @dev Returns the number of the first codepoint in the slice.
     * @param self The slice to operate on.
     * @return The number of the first codepoint in the slice.
     */
    function ord(slice memory self) internal pure returns (uint ret) {
        if (self._len == 0) {
            return 0;
        }

        uint word;
        uint length;
        uint divisor = 2 ** 248;

        // Load the rune into the MSBs of b
        assembly { word:= mload(mload(add(self, 32))) }
        uint b = word / divisor;
        if (b < 0x80) {
            ret = b;
            length = 1;
        } else if(b < 0xE0) {
            ret = b & 0x1F;
            length = 2;
        } else if(b < 0xF0) {
            ret = b & 0x0F;
            length = 3;
        } else {
            ret = b & 0x07;
            length = 4;
        }

        // Check for truncated codepoints
        if (length > self._len) {
            return 0;
        }

        for (uint i = 1; i < length; i++) {
            divisor = divisor / 256;
            b = (word / divisor) & 0xFF;
            if (b & 0xC0 != 0x80) {
                // Invalid UTF-8 sequence
                return 0;
            }
            ret = (ret * 64) | (b & 0x3F);
        }

        return ret;
    }

    /*
     * @dev Returns the keccak-256 hash of the slice.
     * @param self The slice to hash.
     * @return The hash of the slice.
     */
    function keccak(slice memory self) internal pure returns (bytes32 ret) {
        assembly {
            ret := keccak256(mload(add(self, 32)), mload(self))
        }
    }

    /*
     * @dev Returns true if `self` starts with `needle`.
     * @param self The slice to operate on.
     * @param needle The slice to search for.
     * @return True if the slice starts with the provided text, false otherwise.
     */
    function startsWith(slice memory self, slice memory needle) internal pure returns (bool) {
        if (self._len < needle._len) {
            return false;
        }

        if (self._ptr == needle._ptr) {
            return true;
        }

        bool equal;
        assembly {
            let length := mload(needle)
            let selfptr := mload(add(self, 0x20))
            let needleptr := mload(add(needle, 0x20))
            equal := eq(keccak256(selfptr, length), keccak256(needleptr, length))
        }
        return equal;
    }

    /*
     * @dev If `self` starts with `needle`, `needle` is removed from the
     *      beginning of `self`. Otherwise, `self` is unmodified.
     * @param self The slice to operate on.
     * @param needle The slice to search for.
     * @return `self`
     */
    function beyond(slice memory self, slice memory needle) internal pure returns (slice memory) {
        if (self._len < needle._len) {
            return self;
        }

        bool equal = true;
        if (self._ptr != needle._ptr) {
            assembly {
                let length := mload(needle)
                let selfptr := mload(add(self, 0x20))
                let needleptr := mload(add(needle, 0x20))
                equal := eq(keccak256(selfptr, length), keccak256(needleptr, length))
            }
        }

        if (equal) {
            self._len -= needle._len;
            self._ptr += needle._len;
        }

        return self;
    }

    /*
     * @dev Returns true if the slice ends with `needle`.
     * @param self The slice to operate on.
     * @param needle The slice to search for.
     * @return True if the slice starts with the provided text, false otherwise.
     */
    function endsWith(slice memory self, slice memory needle) internal pure returns (bool) {
        if (self._len < needle._len) {
            return false;
        }

        uint selfptr = self._ptr + self._len - needle._len;

        if (selfptr == needle._ptr) {
            return true;
        }

        bool equal;
        assembly {
            let length := mload(needle)
            let needleptr := mload(add(needle, 0x20))
            equal := eq(keccak256(selfptr, length), keccak256(needleptr, length))
        }

        return equal;
    }

    /*
     * @dev If `self` ends with `needle`, `needle` is removed from the
     *      end of `self`. Otherwise, `self` is unmodified.
     * @param self The slice to operate on.
     * @param needle The slice to search for.
     * @return `self`
     */
    function until(slice memory self, slice memory needle) internal pure returns (slice memory) {
        if (self._len < needle._len) {
            return self;
        }

        uint selfptr = self._ptr + self._len - needle._len;
        bool equal = true;
        if (selfptr != needle._ptr) {
            assembly {
                let length := mload(needle)
                let needleptr := mload(add(needle, 0x20))
                equal := eq(keccak256(selfptr, length), keccak256(needleptr, length))
            }
        }

        if (equal) {
            self._len -= needle._len;
        }

        return self;
    }

    // Returns the memory address of the first byte of the first occurrence of
    // `needle` in `self`, or the first byte after `self` if not found.
    function findPtr(uint selflen, uint selfptr, uint needlelen, uint needleptr) private pure returns (uint) {
        uint ptr = selfptr;
        uint idx;

        if (needlelen <= selflen) {
            if (needlelen <= 32) {
                bytes32 mask;
                if (needlelen > 0) {
                    mask = bytes32(~(2 ** (8 * (32 - needlelen)) - 1));
                }

                bytes32 needledata;
                assembly { needledata := and(mload(needleptr), mask) }

                uint end = selfptr + selflen - needlelen;
                bytes32 ptrdata;
                assembly { ptrdata := and(mload(ptr), mask) }

                while (ptrdata != needledata) {
                    if (ptr >= end)
                        return selfptr + selflen;
                    ptr++;
                    assembly { ptrdata := and(mload(ptr), mask) }
                }
                return ptr;
            } else {
                // For long needles, use hashing
                bytes32 hash;
                assembly { hash := keccak256(needleptr, needlelen) }

                for (idx = 0; idx <= selflen - needlelen; idx++) {
                    bytes32 testHash;
                    assembly { testHash := keccak256(ptr, needlelen) }
                    if (hash == testHash)
                        return ptr;
                    ptr += 1;
                }
            }
        }
        return selfptr + selflen;
    }

    // Returns the memory address of the first byte after the last occurrence of
    // `needle` in `self`, or the address of `self` if not found.
    function rfindPtr(uint selflen, uint selfptr, uint needlelen, uint needleptr) private pure returns (uint) {
        uint ptr;

        if (needlelen <= selflen) {
            if (needlelen <= 32) {
                bytes32 mask;
                if (needlelen > 0) {
                    mask = bytes32(~(2 ** (8 * (32 - needlelen)) - 1));
                }

                bytes32 needledata;
                assembly { needledata := and(mload(needleptr), mask) }

                ptr = selfptr + selflen - needlelen;
                bytes32 ptrdata;
                assembly { ptrdata := and(mload(ptr), mask) }

                while (ptrdata != needledata) {
                    if (ptr <= selfptr)
                        return selfptr;
                    ptr--;
                    assembly { ptrdata := and(mload(ptr), mask) }
                }
                return ptr + needlelen;
            } else {
                // For long needles, use hashing
                bytes32 hash;
                assembly { hash := keccak256(needleptr, needlelen) }
                ptr = selfptr + (selflen - needlelen);
                while (ptr >= selfptr) {
                    bytes32 testHash;
                    assembly { testHash := keccak256(ptr, needlelen) }
                    if (hash == testHash)
                        return ptr + needlelen;
                    ptr -= 1;
                }
            }
        }
        return selfptr;
    }

    /*
     * @dev Modifies `self` to contain everything from the first occurrence of
     *      `needle` to the end of the slice. `self` is set to the empty slice
     *      if `needle` is not found.
     * @param self The slice to search and modify.
     * @param needle The text to search for.
     * @return `self`.
     */
    function find(slice memory self, slice memory needle) internal pure returns (slice memory) {
        uint ptr = findPtr(self._len, self._ptr, needle._len, needle._ptr);
        self._len -= ptr - self._ptr;
        self._ptr = ptr;
        return self;
    }

    /*
     * @dev Modifies `self` to contain the part of the string from the start of
     *      `self` to the end of the first occurrence of `needle`. If `needle`
     *      is not found, `self` is set to the empty slice.
     * @param self The slice to search and modify.
     * @param needle The text to search for.
     * @return `self`.
     */
    function rfind(slice memory self, slice memory needle) internal pure returns (slice memory) {
        uint ptr = rfindPtr(self._len, self._ptr, needle._len, needle._ptr);
        self._len = ptr - self._ptr;
        return self;
    }

    /*
     * @dev Splits the slice, setting `self` to everything after the first
     *      occurrence of `needle`, and `token` to everything before it. If
     *      `needle` does not occur in `self`, `self` is set to the empty slice,
     *      and `token` is set to the entirety of `self`.
     * @param self The slice to split.
     * @param needle The text to search for in `self`.
     * @param token An output parameter to which the first token is written.
     * @return `token`.
     */
    function split(slice memory self, slice memory needle, slice memory token) internal pure returns (slice memory) {
        uint ptr = findPtr(self._len, self._ptr, needle._len, needle._ptr);
        token._ptr = self._ptr;
        token._len = ptr - self._ptr;
        if (ptr == self._ptr + self._len) {
            // Not found
            self._len = 0;
        } else {
            self._len -= token._len + needle._len;
            self._ptr = ptr + needle._len;
        }
        return token;
    }

    /*
     * @dev Splits the slice, setting `self` to everything after the first
     *      occurrence of `needle`, and returning everything before it. If
     *      `needle` does not occur in `self`, `self` is set to the empty slice,
     *      and the entirety of `self` is returned.
     * @param self The slice to split.
     * @param needle The text to search for in `self`.
     * @return The part of `self` up to the first occurrence of `delim`.
     */
    function split(slice memory self, slice memory needle) internal pure returns (slice memory token) {
        split(self, needle, token);
    }

    /*
     * @dev Splits the slice, setting `self` to everything before the last
     *      occurrence of `needle`, and `token` to everything after it. If
     *      `needle` does not occur in `self`, `self` is set to the empty slice,
     *      and `token` is set to the entirety of `self`.
     * @param self The slice to split.
     * @param needle The text to search for in `self`.
     * @param token An output parameter to which the first token is written.
     * @return `token`.
     */
    function rsplit(slice memory self, slice memory needle, slice memory token) internal pure returns (slice memory) {
        uint ptr = rfindPtr(self._len, self._ptr, needle._len, needle._ptr);
        token._ptr = ptr;
        token._len = self._len - (ptr - self._ptr);
        if (ptr == self._ptr) {
            // Not found
            self._len = 0;
        } else {
            self._len -= token._len + needle._len;
        }
        return token;
    }

    /*
     * @dev Splits the slice, setting `self` to everything before the last
     *      occurrence of `needle`, and returning everything after it. If
     *      `needle` does not occur in `self`, `self` is set to the empty slice,
     *      and the entirety of `self` is returned.
     * @param self The slice to split.
     * @param needle The text to search for in `self`.
     * @return The part of `self` after the last occurrence of `delim`.
     */
    function rsplit(slice memory self, slice memory needle) internal pure returns (slice memory token) {
        rsplit(self, needle, token);
    }

    /*
     * @dev Counts the number of nonoverlapping occurrences of `needle` in `self`.
     * @param self The slice to search.
     * @param needle The text to search for in `self`.
     * @return The number of occurrences of `needle` found in `self`.
     */
    function count(slice memory self, slice memory needle) internal pure returns (uint cnt) {
        uint ptr = findPtr(self._len, self._ptr, needle._len, needle._ptr) + needle._len;
        while (ptr <= self._ptr + self._len) {
            cnt++;
            ptr = findPtr(self._len - (ptr - self._ptr), ptr, needle._len, needle._ptr) + needle._len;
        }
    }

    /*
     * @dev Returns True if `self` contains `needle`.
     * @param self The slice to search.
     * @param needle The text to search for in `self`.
     * @return True if `needle` is found in `self`, false otherwise.
     */
    function contains(slice memory self, slice memory needle) internal pure returns (bool) {
        return rfindPtr(self._len, self._ptr, needle._len, needle._ptr) != self._ptr;
    }

    /*
     * @dev Returns a newly allocated string containing the concatenation of
     *      `self` and `other`.
     * @param self The first slice to concatenate.
     * @param other The second slice to concatenate.
     * @return The concatenation of the two strings.
     */
    function concat(slice memory self, slice memory other) internal pure returns (string memory) {
        string memory ret = new string(self._len + other._len);
        uint retptr;
        assembly { retptr := add(ret, 32) }
        memcpy(retptr, self._ptr, self._len);
        memcpy(retptr + self._len, other._ptr, other._len);
        return ret;
    }

    /*
     * @dev Joins an array of slices, using `self` as a delimiter, returning a
     *      newly allocated string.
     * @param self The delimiter to use.
     * @param parts A list of slices to join.
     * @return A newly allocated string containing all the slices in `parts`,
     *         joined with `self`.
     */
    function join(slice memory self, slice[] memory parts) internal pure returns (string memory) {
        if (parts.length == 0)
            return "";

        uint length = self._len * (parts.length - 1);
        for(uint i = 0; i < parts.length; i++)
            length += parts[i]._len;

        string memory ret = new string(length);
        uint retptr;
        assembly { retptr := add(ret, 32) }

        for(uint i = 0; i < parts.length; i++) {
            memcpy(retptr, parts[i]._ptr, parts[i]._len);
            retptr += parts[i]._len;
            if (i < parts.length - 1) {
                memcpy(retptr, self._ptr, self._len);
                retptr += self._len;
            }
        }

        return ret;
    }

    // ### No slice functions ###

    /**
     * @dev Splitting a string into an array
     */
    function split(string memory str, string memory delim) internal pure returns (string[] memory) {
        slice memory self = toSlice(str);
        slice memory needle = toSlice(delim);
        string[] memory parts = new string[](count(self, needle) + 1);
        for(uint i = 0; i < parts.length; i++) {
            parts[i] = toString(split(self, needle));
        }
        return parts;
    }

    /**
     * @dev Converts all the values of a string to their corresponding upper case value
     */
    function upper(string memory str) internal pure returns (string memory) {
        bytes memory strBytes = bytes(str);
        bytes memory result = new bytes(strBytes.length);
        for (uint i = 0; i < strBytes.length; i++) {
            result[i] = _upper(strBytes[i]);
        }
        return string(result);
    }

    /**
     * @dev Converts all the values of a string to their corresponding lower case value
     */
    function lower(string memory str) internal pure returns (string memory) {
        bytes memory strBytes = bytes(str);
        bytes memory result = new bytes(strBytes.length);
        for (uint i = 0; i < strBytes.length; i++) {
            result[i] = _lower(strBytes[i]);
        }
        return string(result);
    }

    /**
     * @dev Check equality ignoring upper and lower case
     */
    function equalsIgnoreCase(string memory str, string memory other) internal pure returns (bool) {
        return equals(toSlice(lower(str)), toSlice(lower(other)));
    }

    /**
     * @dev Check if the current string contains the `other` ignoring upper and lower case
     */
    function containsIgnoreCase(string memory str, string memory other) internal pure returns (bool) {
        return contains(toSlice(lower(str)), toSlice(lower(other)));
    }

    /**
     * @dev Check if current string contains digits
     */
    function containsDigits(string memory str) internal pure returns (bool) {
        bytes memory strBytes = bytes(str);
        for (uint256 i = 0; i < strBytes.length; i++) {
            if(uint8(strBytes[i]) >= 48 && uint8(strBytes[i]) <= 57) {
                return true;
            }
        }
        return false;
    }

    /**
     * @dev Check if the string is a signed digit
     */
    function isDigit(string memory str) internal pure returns (bool) {
        return _isDigit(str, true);
    }

    /**
     * @dev Check if the string is a unsigned digit
     */
    function isUDigit(string memory str) internal pure returns (bool) {
        return _isDigit(str, false);
    }

    /**
     * @dev Returns the length of the specified utf8 string
     */
    function utfLength(string memory str) internal pure returns (uint _length) {
        uint i=0;
        bytes memory strBytes = bytes(str);

        while (i<strBytes.length)
        {
            if (strBytes[i]>>7==0)
                i+=1;
            else if (uint8(strBytes[i])>>5==0x6)
                i+=2;
            else if (uint8(strBytes[i])>>4==0xE)
                i+=3;
            else if (strBytes[i]>>3==0x1E)
                i+=4;
            else
                //For safety
                i+=1;

            _length++;
        }
    }

    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "StringUtils: hex length insufficient");
        return string(buffer);
    }

    function substring(string memory str, uint startIndex, uint endIndex) internal pure returns (string memory) {
        bytes memory strBytes = bytes(str);
        bytes memory result = new bytes(endIndex-startIndex);
        for(uint i = startIndex; i < endIndex; i++) {
            result[i-startIndex] = strBytes[i];
        }
        return string(result);
    }

    function ltrim(string memory _in) internal pure returns (string memory) {
        bytes memory _inArr = bytes(_in);
        uint256 _inArrLen = _inArr.length;
        if (_inArrLen == 0)
            return "";
        
        uint256 _start = _inArrLen;
        // Find the index of the first non-whitespace character
        for (uint256 i = 0; i < _inArrLen; i++) {
            bytes1 _char = _inArr[i];
            if (
                _char != 0x20 && // space
                _char != 0x09 && // tab
                _char != 0x0a && // line feed
                _char != 0x0D && // carriage return
                _char != 0x0B && // vertical tab
                _char != 0x00 // null
            ) {
                _start = i;
                break;
            }
        }
        bytes memory _outArr = new bytes(_inArrLen - _start);
        for (uint256 i = _start; i < _inArrLen; i++) {
            _outArr[i - _start] = _inArr[i];
        }
        return string(_outArr);
    }

    function rtrim(string memory _in) internal pure returns (string memory) {
        bytes memory _inArr = bytes(_in);
        uint256 _inArrLen = _inArr.length;
        if (_inArrLen == 0)
            return "";
        
        uint256 _length;
        // Find the index of the last non-whitespace character
        for (uint256 i = _inArrLen; i > 0; i--) {
            bytes1 _char = _inArr[i-1];
            if (
                _char != 0x20 && // space
                _char != 0x09 && // tab
                _char != 0x0a && // line feed
                _char != 0x0D && // carriage return
                _char != 0x0B && // vertical tab
                _char != 0x00 // null
            ) {
                _length = i;
                break;
            }
        }
        bytes memory _outArr = new bytes(_length);
        for (uint256 i = 0; i < _length; i++) {
            _outArr[i] = _inArr[i];
        }
        return string(_outArr);
    }

    function trim(string memory _in) internal pure returns (string memory) {
        return ltrim(rtrim(_in));
    }

    // ### Private functions ###

    /**
     * @dev Convert an alphabetic character to upper case and return the original
     * value when not alphabetic
     * 
     * @param b1 The byte to be converted to upper case
     * @return bytes1 The converted value if the passed value was alphabetic
     *                and in a lower case otherwise returns the original value
     */
    function _upper(bytes1 b1) private pure returns (bytes1) {
        if (b1 >= 0x61 && b1 <= 0x7A) {
            return bytes1(uint8(b1) - 32);
        }
        return b1;
    }

    /**
     * @dev Convert an alphabetic character to lower case and return the original
     * value when not alphabetic
     * 
     * @param b1 The byte to be converted to lower case
     * @return bytes1 The converted value if the passed value was alphabetic
     *                and in a upper case otherwise returns the original value
     */
    function _lower(bytes1 b1) private pure returns (bytes1) {
        if (b1 >= 0x41 && b1 <= 0x5A) {
            return bytes1(uint8(b1) + 32);
        }
        return b1;
    }

    /**
     * @dev Check if the string is a digit ignoring the sign if so indicated
     */
    function _isDigit(string memory str, bool ignoreSign) private pure returns (bool) {
        bytes memory strBytes = bytes(str);

        for (uint256 i = 0; i < strBytes.length; i++) {
            if(ignoreSign && i == 0 && (uint8(strBytes[i]) == 45 || uint8(strBytes[i]) == 43)) {
                continue;
            }

            if(uint8(strBytes[i]) < 48 || uint8(strBytes[i]) > 57) {
                return false;
            }
        }

        return true;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * Integers Library
 * 
 * In summary this is a simple library of integer functions which allow a simple
 * conversion to and from strings
 */
library IntUtils {

    /**
     * @dev Converts an ASCII string value into an uint as long as the string 
     * its self is a valid unsigned integer
     * 
     * @param value The ASCII string to be converted to an unsigned integer
     * @return _ret uint The unsigned value of the ASCII string
     */
    function parseUInt(string memory value) internal pure returns (uint _ret) {
        bytes memory valueBytes = bytes(value);
        uint j = 1;
        for(uint t = valueBytes.length; t > 0; t--) {
            uint i = t - 1;
            assert(uint8(valueBytes[i]) >= 48 && uint8(valueBytes[i]) <= 57);
            _ret += (uint8(valueBytes[i]) - 48)*j;
            j*=10;
        }
    }

    /**
     * @dev Converts an ASCII string value into an int as long as the string 
     * its self is a valid signed integer
     * 
     * @param value The ASCII string to be converted to an signed integer
     * @return _ret int The signed value of the ASCII string
     */
    function parseInt(string memory value) internal pure returns (int _ret) {
        bytes memory valueBytes = bytes(value);
        if(valueBytes.length == 0) {
            return 0;
        }

        int j = 1;
        int sign = (uint8(valueBytes[0]) == 45)? int(-1): int(1);
        uint min = (uint8(valueBytes[0]) == 45 || uint8(valueBytes[0]) == 43)? 1: 0;

        for(uint t = valueBytes.length; t > min; t--) {
            uint i = t - 1;
            assert(uint8(valueBytes[i]) >= 48 && uint8(valueBytes[i]) <= 57);
            _ret += int8(uint8(valueBytes[i]) - 48)*int(j);
            j*=10;
        }

        _ret *= sign;
    }

    /**
     * @dev Converts an unsigned integer to the ASCII string equivalent value
     * 
     * @param value The unsigned integer to be converted to a string
     * @return string The resulting ASCII string value
     */
    function toString(uint value) internal pure returns (string memory) {
        bytes memory tmp = new bytes(32);
        uint i;
        for(i = 0; value > 0; i++) {
            tmp[i] = bytes1(uint8((value % 10) + 48));
            value /= 10;
        }
        bytes memory real = new bytes(i--);
        for(uint j = 0; j < real.length; j++) {
            real[j] = tmp[i--];
        }
        return string(real);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}
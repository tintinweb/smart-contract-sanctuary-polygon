// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;
// pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/access/AccessControl.sol";

contract Hospital_Information is AccessControl  {
   
    /**
    * @dev ADMIN_ROLE constant represents the role assigned to Admin.
    */
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant MY_DEFAULT_ADMIN_ROLE = keccak256("DEFAULT_ADMIN_ROLE");

    
/**
 * @dev Patient struct represents a patient's information.
 *
 * @param name The name of the patient.
 * @param age The age of the patient.
 * @param gender The gender of the patient.
 * @param patientAddress The Ethereum address of the patient.
 * @param emergencyContacts The number of emergency contacts for the patient.
 */
   
    struct Patient {
        string name;
        uint age;
        string gender;
        address patientAddress;
        uint256 emergencyContacts;

    }

/**
 * @dev Doctor struct represents a doctor's information.
 *
 * @param name The name of the doctor.
 * @param doctorAddress The Ethereum address of the doctor.
 * @param specialty The specialty or field of expertise of the doctor.
 * @param registrationNumber The registration number or license number of the doctor.
 * @param hospitalAffiliation The hospital or institution affiliation of the doctor.
 * @param contactInfo The contact information (such as phone number or email) of the doctor.
 */


    struct Doctor {
        string name;
        address doctorAddress;
        string specialty;
        string registrationNumber;
        string hospitalAffiliation;
        uint256 contactInfo;
    }
/**
 * @dev Nurse struct represents a nurse's information.
 *
 * @param name The name of the nurse.
 * @param nurseAddress The Ethereum address of the nurse.
 * @param designation The designation or role of the nurse.
 * @param registrationNumber The registration number or license number of the nurse.
 * @param hospitalAffiliation The hospital or institution affiliation of the nurse.
 * @param contactInfo The contact information (such as phone number or email) of the nurse.
 */

    
    struct Nurse {
        string name;
        address nurseAddress;
        string designation;
        string registrationNumber;
        string hospitalAffiliation;
        uint256 contactInfo;
    }


/**
 * @dev Hospital struct represents a hospital's information.
 *
 * @param name The name of the hospital.
 * @param hospitalAddress The Ethereum address of the hospital.
 * @param contactInfo The contact information (such as phone number or email) of the hospital.
 * @param facilitiesAndServices The facilities and services provided by the hospital.
 */    

    struct Hospital {
        string name;
        address hospitalAddress;
        uint256 contactInfo;
        string facilitiesAndServices;
    }

/**
 * @dev Mapping that stores the IPFS hashes of the PDF `Medical History`, `laboratory Results` and `insuranceInformation` for each Patient address.
 * The key represents the address of the patient, and the value is a string containing the IPFS hash.
 */

    mapping(address => string) public medicalHistory;
    mapping(address => string) public laboratoryResult;
    mapping(address => string) public insuranceInformation;
    
/**
 * @dev Mapping that associates an address with a Nurse struct.
 * The key represents the address of the nurse, and the value is the Nurse struct containing the nurse's information.
 */
    mapping(address => Nurse) public nurses;
/**
 * @dev Mapping that associates an address with a Hospital struct.
 * The key represents the address of the hospital, and the value is the Hospital struct containing the hospital's information.
 */
    mapping(address => Hospital) public hospitals;
/**
 * @dev Mapping that associates an address with a Doctor struct.
 * The key represents the address of the doctor, and the value is the Doctor struct containing the doctor's information.
 */        
    mapping(address => Doctor) public doctors;
/**
 * @dev Mapping that associates an address with a Patient struct.
 * The key represents the address of the patient, and the value is the Patient struct containing the patient's information.
 */   
    mapping(address => Patient) public patients;



/**
 * @dev Contract constructor.
 * Initializes the contract by setting up the `ADMIN_ROLE` and `DEFAULT_ADMIN_ROLE` and assigning it to the deployer of the contract.The Address that is used to deploy the contract has the 
 *`ADMIN_ROLE`.
 */

    constructor() {
         _setupRole(ADMIN_ROLE, msg.sender);
         _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

 // [ HOSPITAL-SECTION ]
   
    
/**
 * @dev Adds a new hospital to the contract.
 * @param _name The name of the hospital.
 * @param _address The Ethereum address of the hospital.
 * @param _contactInfo The contact information (such as phone number or email) of the hospital.
 * @param _facilitiesAndServices The facilities and services provided by the hospital.
 */    
    function addHospital(
        string memory _name,
        address  _address,
        uint256 _contactInfo,
        string memory _facilitiesAndServices
    ) public {
        hospitals[msg.sender] = Hospital({
            name: _name,
            hospitalAddress: _address,
            contactInfo: _contactInfo,
            facilitiesAndServices: _facilitiesAndServices
        });
    }

    function updateHospitalInfo(
       string memory _name,
        address  _address,
        uint256 _contactInfo,
        string memory _facilitiesAndServices
    ) public {

       
        require(msg.sender == doctors[msg.sender].doctorAddress || hasRole(ADMIN_ROLE, msg.sender),"Only `Doctor` Or `Admin` have the Access" );
        require(_address == hospitals[_address].hospitalAddress,"Only for Resgistered users");
        
        hospitals[msg.sender].name =  _name;
        hospitals[msg.sender].hospitalAddress = _address;
        hospitals[msg.sender].contactInfo = _contactInfo;
        hospitals[msg.sender].facilitiesAndServices = _facilitiesAndServices;
   
    
    }
/**
 * @dev Retrieves the information of a hospital based on its address.
 * @param _address The Ethereum address of the hospital.
 * @return The Hospital struct containing the information of the hospital.
 */    

    function getHospital(address _address) public view returns(Hospital memory) {
        return hospitals[_address];
    }
       
    // [NURSE-SECTION]
/**
 * @dev Adds a new nurse to the contract.
 * @param _name The name of the nurse.
 * @param _addr The Ethereum address of the nurse.
 * @param _designation The designation or role of the nurse.
 * @param _registrationNumber The registration number or license number of the nurse.
 * @param _hospitalAffiliation The hospital or institution affiliation of the nurse.
 * @param _contactInfo The contact information (such as phone number or email) of the nurse.
 */    

    function addNurse(
        string memory _name,
        address _addr,
        string memory _designation,
        string memory _registrationNumber,
        string memory _hospitalAffiliation,
        uint256 _contactInfo
    ) public {

        nurses[msg.sender] = Nurse({
            name: _name,
            nurseAddress: _addr,
            designation: _designation,
            registrationNumber: _registrationNumber,
            hospitalAffiliation: _hospitalAffiliation,
            contactInfo: _contactInfo
        });

    }

       function updateNurseInfo(  
            string memory _name,
            address _address,
            string memory _designation,
            string memory _registrationNumber,
            string memory _hospitalAffiliation,
            uint256 _contactInfo
        ) public   {

        

         require(msg.sender == nurses[_address].nurseAddress || hasRole(ADMIN_ROLE, msg.sender),"Only `Nurse` Or `Admin` can have the Access");
      
        require(_address == nurses[_address].nurseAddress,"Only for registered Users");
       
        nurses[_address].name =  _name;
        nurses[_address].nurseAddress = _address;
        nurses[_address].designation = _designation;
        nurses[_address].registrationNumber = _registrationNumber;
        nurses[_address].hospitalAffiliation = _hospitalAffiliation;
        nurses[_address].contactInfo = _contactInfo;
    }
/**
 * @dev Retrieves the information of a nurse based on their address.
 * @param _address The Ethereum address of the nurse.
 * @return The Nurse struct containing the information of the nurse.
 */
        
    function getNurse(address _address) public view returns(Nurse memory) {
        return nurses[_address];
    }
    
    // [ DOCTOR-SECTION ]
/**
 * @dev Adds a new doctor to the contract.
 * @param _name The name of the doctor.
 * @param _addr The Ethereum address of the doctor.
 * @param _specialty The specialty or field of expertise of the doctor.
 * @param _registrationNumber The registration number or license number of the doctor.
 * @param _hospitalAffiliation The hospital or institution affiliation of the doctor.
 * @param _contactInfo The contact information (such as phone number or email) of the doctor.
 */    
    
    function addDoctor(
        string memory _name,
        address _addr,
        string memory _specialty,
        string memory _registrationNumber,
        string memory _hospitalAffiliation,
        uint256 _contactInfo
    ) public {

      
        
        doctors[msg.sender] = Doctor({
            name: _name,
            doctorAddress : _addr,
            specialty: _specialty,
            registrationNumber: _registrationNumber,
            hospitalAffiliation: _hospitalAffiliation,
            contactInfo: _contactInfo
        });
    }

     function updateDoctorInfo(
        string memory _name,
        address _address,
        string memory _specialty,
        string memory _registrationNumber,
        string memory _hospitalAffiliation,
        uint256 _contactInfo
    ) public {


        require(msg.sender == doctors[_address].doctorAddress || hasRole(ADMIN_ROLE, msg.sender),"Only `Doctor` Or `Admin` have the Access");
        require(_address == doctors[_address].doctorAddress,"Only for Registered Users");      

        doctors[_address].name =  _name;
        doctors[_address].doctorAddress = _address;
        doctors[_address].specialty = _specialty;
        doctors[_address].registrationNumber = _registrationNumber;
        doctors[_address].hospitalAffiliation = _hospitalAffiliation;
        doctors[_address].contactInfo = _contactInfo;
    
    }
/**
 * @dev Retrieves the information of a doctor based on their address.
 * @param _address The Ethereum address of the doctor.
 * @return The Doctor struct containing the information of the doctor.
 */  

    function getDoctor(address _address) public view returns(Doctor memory) {
        return doctors[_address];
    }

    // [PATIENT-SECTION]
/**
 * @dev Adds a new patient to the contract.
 * @param _name The name of the patient.
 * @param _age The age of the patient.
 * @param _gender The gender of the patient.
 * @param _address The Ethereum address of the patient.
 * @param _ipfsHashMedicalHistory The IPFS hash of the patient's medical history PDF.
 * @param _ipfsHashLaboratoryResult The IPFS hash of the patient's laboratory result PDF.
 * @param _ipfsHashInsuranceInformation The IPFS hash of the patient's insurance information PDF.
 * @param _emergencyContacts The number of emergency contacts for the patient.
 */    
    
    function addPatient(
        string memory _name,
        uint _age,
        string memory _gender,
        address _address,
        string memory _ipfsHashMedicalHistory,
        string memory _ipfsHashLaboratoryResult,
        string memory _ipfsHashInsuranceInformation,
        uint256 _emergencyContacts
    ) public {

  
        patients[msg.sender] = Patient({
            name: _name,
            age: _age,
            gender: _gender,
            patientAddress: _address,
            emergencyContacts: _emergencyContacts
        });
        medicalHistory[msg.sender] = _ipfsHashMedicalHistory;
        laboratoryResult[msg.sender] = _ipfsHashLaboratoryResult;
        insuranceInformation[msg.sender] = _ipfsHashInsuranceInformation;

    }

     function UpdatePatientInfo(  
        string memory _name,
        uint _age,
        string memory _gender,
        address _address,
        uint256 _emergencyContacts) 
        public   {

        require(msg.sender == patients[_address].patientAddress || msg.sender == nurses[msg.sender].nurseAddress || hasRole(ADMIN_ROLE, msg.sender),"Only Patient Registered patients Or Nurses can Access");
        require(_address == patients[_address].patientAddress,"Only for registered Users");

        patients[_address].name =  _name;
        patients[_address].age = _age;
        patients[_address].gender = _gender;
        patients[_address].patientAddress = _address;
        patients[_address].emergencyContacts = _emergencyContacts;
    }

/**
 * @dev Retrieves the information of a patient based on their address.
 * @param _address The Ethereum address of the patient.
 * @return The Patient struct containing the information of the patient.
 */ 
    
    function getPatient(address _address) public view returns(Patient memory) {
        return patients[_address];
    }

  // [MEDICAL-HISTORY- SECTION]

    function updateMedicalHistory(
        
        string memory _ipfsHashMedicalHistory,
        string memory _ipfsHashLaboratoryResult,
        string memory _ipfsHashInsuranceInformation,
        address _address

    ) public {

        require(msg.sender == doctors[msg.sender].doctorAddress || msg.sender == nurses[msg.sender].nurseAddress || hasRole(ADMIN_ROLE, msg.sender), "Only `Doctor`, `Nurse` and `Admin have the Access");
        
        require(_address == patients[_address].patientAddress,"No Data Found");

        medicalHistory[_address] = _ipfsHashMedicalHistory;
        laboratoryResult[_address] = _ipfsHashLaboratoryResult;
        insuranceInformation[_address] = _ipfsHashInsuranceInformation;
    
    }
/**
 * @dev Updates the address of the admin role.
 * @param _newAdmin The new Ethereum address to be assigned as the admin.
 * Requirements:
 * - The caller must have the ADMIN_ROLE.
 */
  
    function updateAdminAddress(address _newAdmin) public  {
         require(hasRole(ADMIN_ROLE, msg.sender), "Admin Address can be used to call `updateAdminAddress`");
        grantRole(ADMIN_ROLE,_newAdmin);
    }

  





}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/Math.sol";

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = Math.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, Math.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
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
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(account),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleGranted} event.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleRevoked} event.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     *
     * May emit a {RoleRevoked} event.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * May emit a {RoleGranted} event.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleGranted} event.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleRevoked} event.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}
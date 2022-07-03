// SPDX-License-Identifier: ISC
pragma solidity ^0.8.15;

// ====================================================================
// |     ______                   _______                             |
// |    / _____________ __  __   / ____(_____  ____ _____  ________   |
// |   / /_  / ___/ __ `| |/_/  / /_  / / __ \/ __ `/ __ \/ ___/ _ \  |
// |  / __/ / /  / /_/ _>  <   / __/ / / / / / /_/ / / / / /__/  __/  |
// | /_/   /_/   \__,_/_/|_|  /_/   /_/_/ /_/\__,_/_/ /_/\___/\___/   |
// |                                                                  |
// ====================================================================
// ====================== FraxlendPairDeployer ========================
// ====================================================================
// Frax Finance: https://github.com/FraxFinance

// Primary Author
// Drake Evans: https://github.com/DrakeEvans

// Reviewers
// Dennis Ettes: https://github.com/denett
// Sam Kazemian: https://github.com/samkazemian
// Travis Moore: https://github.com/FortisFortuna
// Jack Corddry: https://github.com/corddry
// Rich Gee: https://github.com/zer0blockchain

// ====================================================================

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@rari-capital/solmate/src/utils/SSTORE2.sol";
import "solidity-bytes-utils/contracts/BytesLib.sol";
import "./FraxlendPair.sol";
import "./interfaces/IRateCalculator.sol";
import "./interfaces/IFraxlendWhitelist.sol";
import "./libraries/SafeERC20.sol";

// solhint-disable no-inline-assembly

/// @title FraxlendPairDeployer
/// @author Drake Evans (Frax Finance) https://github.com/drakeevans
/// @notice Deploys and initializes new FraxlendPairs
/// @dev Uses create2 to deploy the pairs, logs an event, and records a list of all deployed pairs
contract FraxlendPairDeployer is Ownable {
    using SafeERC20 for IERC20;
    using Strings for uint256;

    // Constants
    uint256 private constant DEFAULT_MAX_LTV = 75000; // 75% with 1e5 precision
    uint256 private constant GLOBAL_MAX_LTV = 1e8; // 1000x (100,000%) with 1e5 precision, protects from rounding errors in LTV calc
    uint256 private constant DEFAULT_LIQ_FEE = 10000; // 10% with 1e5 precision

    address private contractAddress1;
    address private contractAddress2;

    // Admin contracts
    address internal immutable CIRCUIT_BREAKER;
    address internal immutable COMPTROLLER_ADDRESS;

    // Dependencies
    address private immutable FRAXLEND_WHITELIST;

    /// @notice Emits when a new pair is deployed
    /// @notice The ```LogDeploy``` event is emitted when a new Pair is deployed
    /// @param _name The name of the Pair
    /// @param _address The address of the pair
    /// @param _asset The address of the Asset Token contract
    /// @param _collateral The address of the Collateral Token contract
    /// @param _oracleMultiply The address of the numerator price Oracle
    /// @param _oracleDivide The address of the denominator price Oracle
    /// @param _rateContract The address of the Rate Calculator contract
    /// @param _maxLTV The Maximum Loan-To-Value for a borrower to be considered solvent (1e5 precision)
    /// @param _liquidationFee The fee paid to liquidators given as a % of the repayment (1e5 precision)
    /// @param _maturity The maturity of the Pair
    event LogDeploy(
        string indexed _name,
        address _address,
        address indexed _asset,
        address indexed _collateral,
        address _oracleMultiply,
        address _oracleDivide,
        address _rateContract,
        uint256 _maxLTV,
        uint256 _liquidationFee,
        uint256 _maturity
    );

    /// @notice CREATE2 salt => deployed address
    mapping(bytes32 => address) public deployedPairsBySalt;
    /// @notice hash of name => deployed address
    mapping(string => address) public deployedPairsByName;
    /// @notice List of the names of all deployed Pairs
    string[] public deployedPairsArray;

    constructor(
        address _circuitBreaker,
        address _comptroller,
        address _fraxlendWhitelist
    ) Ownable() {
        CIRCUIT_BREAKER = _circuitBreaker;
        COMPTROLLER_ADDRESS = _comptroller;
        FRAXLEND_WHITELIST = _fraxlendWhitelist;
    }

    function deployedPairsLength() external view returns (uint256) {
        return deployedPairsArray.length;
    }

    function getAllPairAddresses() external view returns (address[] memory) {
        uint256 _lengthOfArray = deployedPairsArray.length;
        address[] memory _addresses = new address[](_lengthOfArray);
        string[] memory _deployedPairsArray = deployedPairsArray;
        for (uint256 i = 0; i < _lengthOfArray; i++) {
            _addresses[i] = deployedPairsByName[_deployedPairsArray[i]];
        }
        return _addresses;
    }

    function setCreationCode(bytes calldata _creationCode) external onlyOwner {
        bytes memory _firstHalf = BytesLib.slice(_creationCode, 0, 13000);
        contractAddress1 = SSTORE2.write(_firstHalf);
        if (_creationCode.length > 13000) {
            bytes memory _secondHalf = BytesLib.slice(_creationCode, 13000, _creationCode.length - 13000);
            contractAddress2 = SSTORE2.write(_secondHalf);
        }
    }

    /// @notice The ```deploy``` function allows anyone to create a custom lending market between an Asset and Collateral Token
    /// @param _configData abi.encode(address _asset, address _collateral, address _oracleMultiply, address _oracleDivide, uint256 _oracleNormalization, address _rateContract, bytes memory _rateInitData)
    /// @return _pairAddress The address to which the Pair was deployed
    function deploy(bytes memory _configData) external returns (address _pairAddress) {
        (address _asset, address _collateral, , , , address _rateContract, ) = abi.decode(
            _configData,
            (address, address, address, address, uint256, address, bytes)
        );
        string memory _name = string(
            abi.encodePacked(
                "FraxlendV1 - ",
                IERC20(_collateral).safeName(),
                "/",
                IERC20(_asset).safeName(),
                " - ",
                IRateCalculator(_rateContract).name(),
                " - ",
                (deployedPairsArray.length + 1).toString()
            )
        );

        _pairAddress = _deployFirst(
            keccak256(abi.encodePacked("public")),
            _configData,
            abi.encode(CIRCUIT_BREAKER, COMPTROLLER_ADDRESS, FRAXLEND_WHITELIST),
            DEFAULT_MAX_LTV,
            DEFAULT_LIQ_FEE,
            0,
            0,
            false,
            false
        );

        _deploySecond(_name, _pairAddress, _configData, new address[](0), new address[](0));

        _logDeploy(_name, _pairAddress, _configData, DEFAULT_MAX_LTV, DEFAULT_LIQ_FEE, 0);
    }

    /// @notice The ```deployCustom``` function allows whitelisted users to deploy custom Term Sheets for OTC debt structuring
    /// @dev Caller must be added to FraxLedWhitelist
    /// @param _name The name of the Pair
    /// @param _configData abi.encode(address _asset, address _collateral, address _oracleMultiply, address _oracleDivide, uint256 _oracleNormalization, address _rateContract, bytes memory _rateInitData)
    /// @param _maxLTV The Maximum Loan-To-Value for a borrower to be considered solvent (1e5 precision)
    /// @param _liquidationFee The fee paid to liquidators given as a % of the repayment (1e5 precision)
    /// @param _maturity The maturity of the Pair
    /// @param _approvedBorrowers An array of approved borrower addresses
    /// @param _approvedLenders An array of approved lender addresses
    /// @return _pairAddress The address to which the Pair was deployed
    function deployCustom(
        string memory _name,
        bytes memory _configData,
        uint256 _maxLTV,
        uint256 _liquidationFee,
        uint256 _maturity,
        uint256 _penaltyRate,
        address[] memory _approvedBorrowers,
        address[] memory _approvedLenders
    ) external returns (address _pairAddress) {
        require(_maxLTV <= GLOBAL_MAX_LTV, "FraxlendPairDeployer: _maxLTV is too large");
        require(
            IFraxlendWhitelist(FRAXLEND_WHITELIST).fraxlendDeployerWhitelist(msg.sender),
            "FraxlendPairDeployer: Only whitelisted addresses"
        );

        _pairAddress = _deployFirst(
            keccak256(abi.encodePacked(_name)),
            _configData,
            abi.encode(CIRCUIT_BREAKER, COMPTROLLER_ADDRESS, FRAXLEND_WHITELIST),
            _maxLTV,
            _liquidationFee,
            _maturity,
            _penaltyRate,
            _approvedBorrowers.length > 0,
            _approvedLenders.length > 0
        );

        _deploySecond(_name, _pairAddress, _configData, _approvedBorrowers, _approvedLenders);

        _logDeploy(_name, _pairAddress, _configData, _maxLTV, _liquidationFee, _maturity);
    }

    /// @notice The ```_deployFirst``` function is an internal function with deploys the pair
    /// @param _configData abi.encode(address _asset, address _collateral, address _oracleMultiply, address _oracleDivide, uint256 _oracleNormalization, address _rateContract, bytes memory _rateInitData)
    /// @param _maxLTV The Maximum Loan-To-Value for a borrower to be considered solvent (1e5 precision)
    /// @param _liquidationFee The fee paid to liquidators given as a % of the repayment (1e5 precision)
    /// @param _maturity The maturity of the Pair
    /// @param _isBorrowerWhitelistActive Enables borrower whitelist
    /// @param _isLenderWhitelistActive Enables lender whitelist
    /// @return _pairAddress The address to which the Pair was deployed
    function _deployFirst(
        bytes32 _saltSeed,
        bytes memory _configData,
        bytes memory _immutables,
        uint256 _maxLTV,
        uint256 _liquidationFee,
        uint256 _maturity,
        uint256 _penaltyRate,
        bool _isBorrowerWhitelistActive,
        bool _isLenderWhitelistActive
    ) private returns (address _pairAddress) {
        {
            // _saltSeed is the same for all public pairs so duplicates cannot be created
            bytes32 salt = keccak256(
                abi.encodePacked(_saltSeed, _configData, _isBorrowerWhitelistActive, _isLenderWhitelistActive)
            );
            require(deployedPairsBySalt[salt] == address(0), "FraxlendPairDeployer: Pair already deployed");

            bytes memory _creationCode = BytesLib.concat(
                SSTORE2.read(contractAddress1),
                SSTORE2.read(contractAddress2)
            );
            bytes memory bytecode = abi.encodePacked(
                _creationCode,
                abi.encode(
                    _configData,
                    _immutables,
                    _maxLTV,
                    _liquidationFee,
                    _maturity,
                    _penaltyRate,
                    _isBorrowerWhitelistActive,
                    _isLenderWhitelistActive
                )
            );

            assembly {
                _pairAddress := create2(0, add(bytecode, 32), mload(bytecode), salt)
            }
            require(_pairAddress != address(0), "FraxlendPairDeployer: create2 failed");

            deployedPairsBySalt[salt] = _pairAddress;
        }

        return _pairAddress;
    }

    /// @notice The ```_deploySecond``` function is the second part of deployment, it invoked the initialize() on the Pair
    /// @param _name The name of the Pair
    /// @param _pairAddress The address of the Pair
    /// @param _configData abi.encode(address _asset, address _collateral, address _oracleMultiply, address _oracleDivide, uint256 _oracleNormalization, address _rateContract, bytes memory _rateInitData)
    /// @param _approvedBorrowers An array of approved borrower addresses
    /// @param _approvedLenders An array of approved lender addresses
    function _deploySecond(
        string memory _name,
        address _pairAddress,
        bytes memory _configData,
        address[] memory _approvedBorrowers,
        address[] memory _approvedLenders
    ) private {
        (, , , , , , bytes memory _rateInitData) = abi.decode(
            _configData,
            (address, address, address, address, uint256, address, bytes)
        );
        require(deployedPairsByName[_name] == address(0), "FraxlendPairDeployer: Pair name must be unique");
        deployedPairsByName[_name] = _pairAddress;
        deployedPairsArray.push(_name);

        // Set additional values for FraxlendPair
        FraxlendPair(_pairAddress).initialize(_name, _approvedBorrowers, _approvedLenders, _rateInitData);
    }

    function _logDeploy(
        string memory _name,
        address _pairAddress,
        bytes memory _configData,
        uint256 _maxLTV,
        uint256 _liquidationFee,
        uint256 _maturity
    ) private {
        (
            address _asset,
            address _collateral,
            address _oracleMultiply,
            address _oracleDivide,
            ,
            address _rateContract,

        ) = abi.decode(_configData, (address, address, address, address, uint256, address, bytes));
        emit LogDeploy(
            _name,
            _pairAddress,
            _asset,
            _collateral,
            _oracleMultiply,
            _oracleDivide,
            _rateContract,
            _maxLTV,
            _liquidationFee,
            _maturity
        );
    }
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
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Read and write to persistent storage at a fraction of the cost.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/utils/SSTORE2.sol)
/// @author Modified from 0xSequence (https://github.com/0xSequence/sstore2/blob/master/contracts/SSTORE2.sol)
library SSTORE2 {
    uint256 internal constant DATA_OFFSET = 1; // We skip the first byte as it's a STOP opcode to ensure the contract can't be called.

    /*//////////////////////////////////////////////////////////////
                               WRITE LOGIC
    //////////////////////////////////////////////////////////////*/

    function write(bytes memory data) internal returns (address pointer) {
        // Prefix the bytecode with a STOP opcode to ensure it cannot be called.
        bytes memory runtimeCode = abi.encodePacked(hex"00", data);

        bytes memory creationCode = abi.encodePacked(
            //---------------------------------------------------------------------------------------------------------------//
            // Opcode  | Opcode + Arguments  | Description  | Stack View                                                     //
            //---------------------------------------------------------------------------------------------------------------//
            // 0x60    |  0x600B             | PUSH1 11     | codeOffset                                                     //
            // 0x59    |  0x59               | MSIZE        | 0 codeOffset                                                   //
            // 0x81    |  0x81               | DUP2         | codeOffset 0 codeOffset                                        //
            // 0x38    |  0x38               | CODESIZE     | codeSize codeOffset 0 codeOffset                               //
            // 0x03    |  0x03               | SUB          | (codeSize - codeOffset) 0 codeOffset                           //
            // 0x80    |  0x80               | DUP          | (codeSize - codeOffset) (codeSize - codeOffset) 0 codeOffset   //
            // 0x92    |  0x92               | SWAP3        | codeOffset (codeSize - codeOffset) 0 (codeSize - codeOffset)   //
            // 0x59    |  0x59               | MSIZE        | 0 codeOffset (codeSize - codeOffset) 0 (codeSize - codeOffset) //
            // 0x39    |  0x39               | CODECOPY     | 0 (codeSize - codeOffset)                                      //
            // 0xf3    |  0xf3               | RETURN       |                                                                //
            //---------------------------------------------------------------------------------------------------------------//
            hex"60_0B_59_81_38_03_80_92_59_39_F3", // Returns all code in the contract except for the first 11 (0B in hex) bytes.
            runtimeCode // The bytecode we want the contract to have after deployment. Capped at 1 byte less than the code size limit.
        );

        assembly {
            // Deploy a new contract with the generated creation code.
            // We start 32 bytes into the code to avoid copying the byte length.
            pointer := create(0, add(creationCode, 32), mload(creationCode))
        }

        require(pointer != address(0), "DEPLOYMENT_FAILED");
    }

    /*//////////////////////////////////////////////////////////////
                               READ LOGIC
    //////////////////////////////////////////////////////////////*/

    function read(address pointer) internal view returns (bytes memory) {
        return readBytecode(pointer, DATA_OFFSET, pointer.code.length - DATA_OFFSET);
    }

    function read(address pointer, uint256 start) internal view returns (bytes memory) {
        start += DATA_OFFSET;

        return readBytecode(pointer, start, pointer.code.length - start);
    }

    function read(
        address pointer,
        uint256 start,
        uint256 end
    ) internal view returns (bytes memory) {
        start += DATA_OFFSET;
        end += DATA_OFFSET;

        require(pointer.code.length >= end, "OUT_OF_BOUNDS");

        return readBytecode(pointer, start, end - start);
    }

    /*//////////////////////////////////////////////////////////////
                          INTERNAL HELPER LOGIC
    //////////////////////////////////////////////////////////////*/

    function readBytecode(
        address pointer,
        uint256 start,
        uint256 size
    ) private view returns (bytes memory data) {
        assembly {
            // Get a pointer to some free memory.
            data := mload(0x40)

            // Update the free memory pointer to prevent overriding our data.
            // We use and(x, not(31)) as a cheaper equivalent to sub(x, mod(x, 32)).
            // Adding 31 to size and running the result through the logic above ensures
            // the memory pointer remains word-aligned, following the Solidity convention.
            mstore(0x40, add(data, and(add(add(size, 32), 31), not(31))))

            // Store the size of the data in the first 32 byte chunk of free memory.
            mstore(data, size)

            // Copy the code into memory right after the 32 bytes we used to store the size.
            extcodecopy(pointer, add(data, 32), start, size)
        }
    }
}

// SPDX-License-Identifier: Unlicense
/*
 * @title Solidity Bytes Arrays Utils
 * @author Gonçalo Sá <[email protected]>
 *
 * @dev Bytes tightly packed arrays utility library for ethereum contracts written in Solidity.
 *      The library lets you concatenate, slice and type cast bytes arrays both in memory and storage.
 */
pragma solidity >=0.8.0 <0.9.0;


library BytesLib {
    function concat(
        bytes memory _preBytes,
        bytes memory _postBytes
    )
        internal
        pure
        returns (bytes memory)
    {
        bytes memory tempBytes;

        assembly {
            // Get a location of some free memory and store it in tempBytes as
            // Solidity does for memory variables.
            tempBytes := mload(0x40)

            // Store the length of the first bytes array at the beginning of
            // the memory for tempBytes.
            let length := mload(_preBytes)
            mstore(tempBytes, length)

            // Maintain a memory counter for the current write location in the
            // temp bytes array by adding the 32 bytes for the array length to
            // the starting location.
            let mc := add(tempBytes, 0x20)
            // Stop copying when the memory counter reaches the length of the
            // first bytes array.
            let end := add(mc, length)

            for {
                // Initialize a copy counter to the start of the _preBytes data,
                // 32 bytes into its memory.
                let cc := add(_preBytes, 0x20)
            } lt(mc, end) {
                // Increase both counters by 32 bytes each iteration.
                mc := add(mc, 0x20)
                cc := add(cc, 0x20)
            } {
                // Write the _preBytes data into the tempBytes memory 32 bytes
                // at a time.
                mstore(mc, mload(cc))
            }

            // Add the length of _postBytes to the current length of tempBytes
            // and store it as the new length in the first 32 bytes of the
            // tempBytes memory.
            length := mload(_postBytes)
            mstore(tempBytes, add(length, mload(tempBytes)))

            // Move the memory counter back from a multiple of 0x20 to the
            // actual end of the _preBytes data.
            mc := end
            // Stop copying when the memory counter reaches the new combined
            // length of the arrays.
            end := add(mc, length)

            for {
                let cc := add(_postBytes, 0x20)
            } lt(mc, end) {
                mc := add(mc, 0x20)
                cc := add(cc, 0x20)
            } {
                mstore(mc, mload(cc))
            }

            // Update the free-memory pointer by padding our last write location
            // to 32 bytes: add 31 bytes to the end of tempBytes to move to the
            // next 32 byte block, then round down to the nearest multiple of
            // 32. If the sum of the length of the two arrays is zero then add
            // one before rounding down to leave a blank 32 bytes (the length block with 0).
            mstore(0x40, and(
              add(add(end, iszero(add(length, mload(_preBytes)))), 31),
              not(31) // Round down to the nearest 32 bytes.
            ))
        }

        return tempBytes;
    }

    function concatStorage(bytes storage _preBytes, bytes memory _postBytes) internal {
        assembly {
            // Read the first 32 bytes of _preBytes storage, which is the length
            // of the array. (We don't need to use the offset into the slot
            // because arrays use the entire slot.)
            let fslot := sload(_preBytes.slot)
            // Arrays of 31 bytes or less have an even value in their slot,
            // while longer arrays have an odd value. The actual length is
            // the slot divided by two for odd values, and the lowest order
            // byte divided by two for even values.
            // If the slot is even, bitwise and the slot with 255 and divide by
            // two to get the length. If the slot is odd, bitwise and the slot
            // with -1 and divide by two.
            let slength := div(and(fslot, sub(mul(0x100, iszero(and(fslot, 1))), 1)), 2)
            let mlength := mload(_postBytes)
            let newlength := add(slength, mlength)
            // slength can contain both the length and contents of the array
            // if length < 32 bytes so let's prepare for that
            // v. http://solidity.readthedocs.io/en/latest/miscellaneous.html#layout-of-state-variables-in-storage
            switch add(lt(slength, 32), lt(newlength, 32))
            case 2 {
                // Since the new array still fits in the slot, we just need to
                // update the contents of the slot.
                // uint256(bytes_storage) = uint256(bytes_storage) + uint256(bytes_memory) + new_length
                sstore(
                    _preBytes.slot,
                    // all the modifications to the slot are inside this
                    // next block
                    add(
                        // we can just add to the slot contents because the
                        // bytes we want to change are the LSBs
                        fslot,
                        add(
                            mul(
                                div(
                                    // load the bytes from memory
                                    mload(add(_postBytes, 0x20)),
                                    // zero all bytes to the right
                                    exp(0x100, sub(32, mlength))
                                ),
                                // and now shift left the number of bytes to
                                // leave space for the length in the slot
                                exp(0x100, sub(32, newlength))
                            ),
                            // increase length by the double of the memory
                            // bytes length
                            mul(mlength, 2)
                        )
                    )
                )
            }
            case 1 {
                // The stored value fits in the slot, but the combined value
                // will exceed it.
                // get the keccak hash to get the contents of the array
                mstore(0x0, _preBytes.slot)
                let sc := add(keccak256(0x0, 0x20), div(slength, 32))

                // save new length
                sstore(_preBytes.slot, add(mul(newlength, 2), 1))

                // The contents of the _postBytes array start 32 bytes into
                // the structure. Our first read should obtain the `submod`
                // bytes that can fit into the unused space in the last word
                // of the stored array. To get this, we read 32 bytes starting
                // from `submod`, so the data we read overlaps with the array
                // contents by `submod` bytes. Masking the lowest-order
                // `submod` bytes allows us to add that value directly to the
                // stored value.

                let submod := sub(32, slength)
                let mc := add(_postBytes, submod)
                let end := add(_postBytes, mlength)
                let mask := sub(exp(0x100, submod), 1)

                sstore(
                    sc,
                    add(
                        and(
                            fslot,
                            0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff00
                        ),
                        and(mload(mc), mask)
                    )
                )

                for {
                    mc := add(mc, 0x20)
                    sc := add(sc, 1)
                } lt(mc, end) {
                    sc := add(sc, 1)
                    mc := add(mc, 0x20)
                } {
                    sstore(sc, mload(mc))
                }

                mask := exp(0x100, sub(mc, end))

                sstore(sc, mul(div(mload(mc), mask), mask))
            }
            default {
                // get the keccak hash to get the contents of the array
                mstore(0x0, _preBytes.slot)
                // Start copying to the last used word of the stored array.
                let sc := add(keccak256(0x0, 0x20), div(slength, 32))

                // save new length
                sstore(_preBytes.slot, add(mul(newlength, 2), 1))

                // Copy over the first `submod` bytes of the new data as in
                // case 1 above.
                let slengthmod := mod(slength, 32)
                let mlengthmod := mod(mlength, 32)
                let submod := sub(32, slengthmod)
                let mc := add(_postBytes, submod)
                let end := add(_postBytes, mlength)
                let mask := sub(exp(0x100, submod), 1)

                sstore(sc, add(sload(sc), and(mload(mc), mask)))

                for {
                    sc := add(sc, 1)
                    mc := add(mc, 0x20)
                } lt(mc, end) {
                    sc := add(sc, 1)
                    mc := add(mc, 0x20)
                } {
                    sstore(sc, mload(mc))
                }

                mask := exp(0x100, sub(mc, end))

                sstore(sc, mul(div(mload(mc), mask), mask))
            }
        }
    }

    function slice(
        bytes memory _bytes,
        uint256 _start,
        uint256 _length
    )
        internal
        pure
        returns (bytes memory)
    {
        require(_length + 31 >= _length, "slice_overflow");
        require(_bytes.length >= _start + _length, "slice_outOfBounds");

        bytes memory tempBytes;

        assembly {
            switch iszero(_length)
            case 0 {
                // Get a location of some free memory and store it in tempBytes as
                // Solidity does for memory variables.
                tempBytes := mload(0x40)

                // The first word of the slice result is potentially a partial
                // word read from the original array. To read it, we calculate
                // the length of that partial word and start copying that many
                // bytes into the array. The first word we copy will start with
                // data we don't care about, but the last `lengthmod` bytes will
                // land at the beginning of the contents of the new array. When
                // we're done copying, we overwrite the full first word with
                // the actual length of the slice.
                let lengthmod := and(_length, 31)

                // The multiplication in the next line is necessary
                // because when slicing multiples of 32 bytes (lengthmod == 0)
                // the following copy loop was copying the origin's length
                // and then ending prematurely not copying everything it should.
                let mc := add(add(tempBytes, lengthmod), mul(0x20, iszero(lengthmod)))
                let end := add(mc, _length)

                for {
                    // The multiplication in the next line has the same exact purpose
                    // as the one above.
                    let cc := add(add(add(_bytes, lengthmod), mul(0x20, iszero(lengthmod))), _start)
                } lt(mc, end) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } {
                    mstore(mc, mload(cc))
                }

                mstore(tempBytes, _length)

                //update free-memory pointer
                //allocating the array padded to 32 bytes like the compiler does now
                mstore(0x40, and(add(mc, 31), not(31)))
            }
            //if we want a zero-length slice let's just return a zero-length array
            default {
                tempBytes := mload(0x40)
                //zero out the 32 bytes slice we are about to return
                //we need to do it because Solidity does not garbage collect
                mstore(tempBytes, 0)

                mstore(0x40, add(tempBytes, 0x20))
            }
        }

        return tempBytes;
    }

    function toAddress(bytes memory _bytes, uint256 _start) internal pure returns (address) {
        require(_bytes.length >= _start + 20, "toAddress_outOfBounds");
        address tempAddress;

        assembly {
            tempAddress := div(mload(add(add(_bytes, 0x20), _start)), 0x1000000000000000000000000)
        }

        return tempAddress;
    }

    function toUint8(bytes memory _bytes, uint256 _start) internal pure returns (uint8) {
        require(_bytes.length >= _start + 1 , "toUint8_outOfBounds");
        uint8 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x1), _start))
        }

        return tempUint;
    }

    function toUint16(bytes memory _bytes, uint256 _start) internal pure returns (uint16) {
        require(_bytes.length >= _start + 2, "toUint16_outOfBounds");
        uint16 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x2), _start))
        }

        return tempUint;
    }

    function toUint32(bytes memory _bytes, uint256 _start) internal pure returns (uint32) {
        require(_bytes.length >= _start + 4, "toUint32_outOfBounds");
        uint32 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x4), _start))
        }

        return tempUint;
    }

    function toUint64(bytes memory _bytes, uint256 _start) internal pure returns (uint64) {
        require(_bytes.length >= _start + 8, "toUint64_outOfBounds");
        uint64 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x8), _start))
        }

        return tempUint;
    }

    function toUint96(bytes memory _bytes, uint256 _start) internal pure returns (uint96) {
        require(_bytes.length >= _start + 12, "toUint96_outOfBounds");
        uint96 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0xc), _start))
        }

        return tempUint;
    }

    function toUint128(bytes memory _bytes, uint256 _start) internal pure returns (uint128) {
        require(_bytes.length >= _start + 16, "toUint128_outOfBounds");
        uint128 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x10), _start))
        }

        return tempUint;
    }

    function toUint256(bytes memory _bytes, uint256 _start) internal pure returns (uint256) {
        require(_bytes.length >= _start + 32, "toUint256_outOfBounds");
        uint256 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x20), _start))
        }

        return tempUint;
    }

    function toBytes32(bytes memory _bytes, uint256 _start) internal pure returns (bytes32) {
        require(_bytes.length >= _start + 32, "toBytes32_outOfBounds");
        bytes32 tempBytes32;

        assembly {
            tempBytes32 := mload(add(add(_bytes, 0x20), _start))
        }

        return tempBytes32;
    }

    function equal(bytes memory _preBytes, bytes memory _postBytes) internal pure returns (bool) {
        bool success = true;

        assembly {
            let length := mload(_preBytes)

            // if lengths don't match the arrays are not equal
            switch eq(length, mload(_postBytes))
            case 1 {
                // cb is a circuit breaker in the for loop since there's
                //  no said feature for inline assembly loops
                // cb = 1 - don't breaker
                // cb = 0 - break
                let cb := 1

                let mc := add(_preBytes, 0x20)
                let end := add(mc, length)

                for {
                    let cc := add(_postBytes, 0x20)
                // the next line is the loop condition:
                // while(uint256(mc < end) + cb == 2)
                } eq(add(lt(mc, end), cb), 2) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } {
                    // if any of these checks fails then arrays are not equal
                    if iszero(eq(mload(mc), mload(cc))) {
                        // unsuccess:
                        success := 0
                        cb := 0
                    }
                }
            }
            default {
                // unsuccess:
                success := 0
            }
        }

        return success;
    }

    function equalStorage(
        bytes storage _preBytes,
        bytes memory _postBytes
    )
        internal
        view
        returns (bool)
    {
        bool success = true;

        assembly {
            // we know _preBytes_offset is 0
            let fslot := sload(_preBytes.slot)
            // Decode the length of the stored array like in concatStorage().
            let slength := div(and(fslot, sub(mul(0x100, iszero(and(fslot, 1))), 1)), 2)
            let mlength := mload(_postBytes)

            // if lengths don't match the arrays are not equal
            switch eq(slength, mlength)
            case 1 {
                // slength can contain both the length and contents of the array
                // if length < 32 bytes so let's prepare for that
                // v. http://solidity.readthedocs.io/en/latest/miscellaneous.html#layout-of-state-variables-in-storage
                if iszero(iszero(slength)) {
                    switch lt(slength, 32)
                    case 1 {
                        // blank the last byte which is the length
                        fslot := mul(div(fslot, 0x100), 0x100)

                        if iszero(eq(fslot, mload(add(_postBytes, 0x20)))) {
                            // unsuccess:
                            success := 0
                        }
                    }
                    default {
                        // cb is a circuit breaker in the for loop since there's
                        //  no said feature for inline assembly loops
                        // cb = 1 - don't breaker
                        // cb = 0 - break
                        let cb := 1

                        // get the keccak hash to get the contents of the array
                        mstore(0x0, _preBytes.slot)
                        let sc := keccak256(0x0, 0x20)

                        let mc := add(_postBytes, 0x20)
                        let end := add(mc, mlength)

                        // the next line is the loop condition:
                        // while(uint256(mc < end) + cb == 2)
                        for {} eq(add(lt(mc, end), cb), 2) {
                            sc := add(sc, 1)
                            mc := add(mc, 0x20)
                        } {
                            if iszero(eq(sload(sc), mload(mc))) {
                                // unsuccess:
                                success := 0
                                cb := 0
                            }
                        }
                    }
                }
            }
            default {
                // unsuccess:
                success := 0
            }
        }

        return success;
    }
}

// SPDX-License-Identifier: ISC
pragma solidity ^0.8.15;

// ====================================================================
// |     ______                   _______                             |
// |    / _____________ __  __   / ____(_____  ____ _____  ________   |
// |   / /_  / ___/ __ `| |/_/  / /_  / / __ \/ __ `/ __ \/ ___/ _ \  |
// |  / __/ / /  / /_/ _>  <   / __/ / / / / / /_/ / / / / /__/  __/  |
// | /_/   /_/   \__,_/_/|_|  /_/   /_/_/ /_/\__,_/_/ /_/\___/\___/   |
// |                                                                  |
// ====================================================================
// ========================== FraxlendPair ============================
// ====================================================================
// Frax Finance: https://github.com/FraxFinance

// Primary Author
// Drake Evans: https://github.com/DrakeEvans

// Reviewers
// Dennis Ettes: https://github.com/denett
// Sam Kazemian: https://github.com/samkazemian
// Travis Moore: https://github.com/FortisFortuna
// Jack Corddry: https://github.com/corddry
// Rich Gee: https://github.com/zer0blockchain

// ====================================================================

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "./FraxlendPairConstants.sol";
import "./FraxlendPairCore.sol";
import "./libraries/VaultAccount.sol";
import "./libraries/SafeERC20.sol";
import "./interfaces/IERC4626.sol";
import "./interfaces/IFraxlendWhitelist.sol";
import "./interfaces/IRateCalculator.sol";
import "./interfaces/ISwapper.sol";

contract FraxlendPair is FraxlendPairCore {
    using VaultAccountingLibrary for VaultAccount;
    using SafeERC20 for IERC20;

    constructor(
        bytes memory _configData,
        bytes memory _immutables,
        uint256 _maxLTV,
        uint256 _liquidationFee,
        uint256 _maturity,
        uint256 _penaltyRate,
        bool _isBorrowerWhitelistActive,
        bool _isLenderWhitelistActive
    )
        FraxlendPairCore(
            _configData,
            _immutables,
            _maxLTV,
            _liquidationFee,
            _maturity,
            _penaltyRate,
            _isBorrowerWhitelistActive,
            _isLenderWhitelistActive
        )
        ERC20("", "")
        Pausable()
    {}

    // ============================================================================================
    // ERC20 Metadata
    // ============================================================================================

    function name() public view override(ERC20, IERC20Metadata) returns (string memory) {
        return nameOfContract;
    }

    function symbol() public view override(ERC20, IERC20Metadata) returns (string memory) {
        // prettier-ignore
        // solhint-disable-next-line max-line-length
        return string(abi.encodePacked("FraxlendV1 - ", collateralContract.safeSymbol(), "/", assetContract.safeSymbol()));
    }

    function decimals() public pure override(ERC20, IERC20Metadata) returns (uint8) {
        return 18;
    }

    // totalSupply for fToken ERC20 compatibility
    function totalSupply() public view override(ERC20, IERC20) returns (uint256) {
        return totalAsset.shares;
    }

    // ============================================================================================
    // ERC4626 Views
    // ============================================================================================
    function asset() external view returns (address) {
        return address(assetContract);
    }

    function totalAssets() public view virtual returns (uint256) {
        return totalAsset.amount;
    }

    function assetsPerShare() external view returns (uint256 _assetsPerUnitShare) {
        _assetsPerUnitShare = totalAsset.toAmount(1e18, false);
    }

    function assetsOf(address _depositor) external view returns (uint256 _assets) {
        _assets = totalAsset.toAmount(balanceOf(_depositor), false);
    }

    function convertToShares(uint256 _amount) external view returns (uint256) {
        return totalAsset.toShares(_amount, false);
    }

    function convertToAssets(uint256 _shares) external view returns (uint256) {
        return totalAsset.toAmount(_shares, false);
    }

    function previewDeposit(uint256 _amount) external view returns (uint256) {
        return totalAsset.toShares(_amount, false);
    }

    function previewMint(uint256 _shares) external view returns (uint256) {
        return totalAsset.toAmount(_shares, true);
    }

    function previewWithdraw(uint256 _amount) external view returns (uint256) {
        return totalAsset.toShares(_amount, true);
    }

    function previewRedeem(uint256 _shares) external view returns (uint256) {
        return totalAsset.toAmount(_shares, false);
    }

    function maxDeposit(address) external pure returns (uint256) {
        return type(uint128).max;
    }

    function maxMint(address) external pure returns (uint256) {
        return type(uint128).max;
    }

    function maxWithdraw(address owner) external view returns (uint256) {
        return totalAsset.toAmount(balanceOf(owner), false);
    }

    function maxRedeem(address owner) external view returns (uint256) {
        return balanceOf(owner);
    }

    // ============================================================================================
    // Functions: Protocol Configuration (Fees & Swap Contracts)
    // ============================================================================================
    event ChangeFee(uint32 _newFee);

    function changeFee(uint16 _newFee) external whenNotPaused onlyOwner {
        if (_newFee > MAX_PROTOCOL_FEE) {
            revert BadProtocolFee();
        }
        currentRateInfo.feeToProtocolRate = _newFee;
        emit ChangeFee(_newFee);
    }

    event WithdrawFees(uint128 _shares, address _recipient, uint256 _amountToTransfer);

    function withdrawFees(uint128 _shares, address _recipient) external onlyOwner returns (uint256 _amountToTransfer) {
        // Grab some data from state to save gas
        VaultAccount memory _totalAsset = totalAsset;
        VaultAccount memory _totalBorrow = totalBorrow;

        // Take all available if 0 value passed
        if (_shares == 0) _shares = uint128(balanceOf(address(this)));

        // We must calculate this before we subtract from _totalAsset or invoke _burn
        _amountToTransfer = _totalAsset.toAmount(_shares, true);

        // Check for sufficient withdraw liquidity
        uint256 _assetsAvailable = _totalAssetAvailable(_totalAsset, _totalBorrow);
        if (_assetsAvailable < _amountToTransfer) {
            revert InsufficientAssetsInContract(_assetsAvailable, _amountToTransfer);
        }

        // Effects: bookkeeping
        _totalAsset.amount -= uint128(_amountToTransfer);
        _totalAsset.shares -= _shares;

        // Effects: write to states
        // NOTE: will revert if _shares > balanceOf(address(this))
        _burn(address(this), _shares);
        totalAsset = _totalAsset;

        // Interactions
        assetContract.safeTransfer(_recipient, _amountToTransfer);
        emit WithdrawFees(_shares, _recipient, _amountToTransfer);
    }

    event SetSwapper(address _swapper, bool _approval);

    function setSwapper(address _swapper, bool _approval) external onlyOwner {
        swappers[_swapper] = _approval;
        emit SetSwapper(_swapper, _approval);
    }

    function setApprovedLenders(address[] calldata _lenders, bool _approval) external approvedLender(msg.sender) {
        for (uint256 i = 0; i < _lenders.length; i++) {
            approvedLenders[_lenders[i]] = _approval;
        }
    }

    function setApprovedBorrowers(address[] calldata _borrowers, bool _approval) external approvedBorrower {
        for (uint256 i = 0; i < _borrowers.length; i++) {
            approvedBorrowers[_borrowers[i]] = _approval;
        }
    }

    function pause() external {
        if (
            msg.sender != CIRCUIT_BREAKER &&
            msg.sender != COMPTROLLER_ADDRESS &&
            msg.sender != owner() &&
            msg.sender != DEPLOYER_CONTRACT
        ) {
            revert ProtocolOrOwnerOnly();
        }
        _addInterest(); // accrue any interest prior to pausing as it won't accrue during pause
        _pause();
    }

    function unpause() external {
        if (msg.sender != COMPTROLLER_ADDRESS && msg.sender != owner()) {
            revert ProtocolOrOwnerOnly();
        }
        // Resets the lastTimestamp which has the effect of no interest accruing over the pause period
        _addInterest();
        _unpause();
    }
}

// SPDX-License-Identifier: ISC
pragma solidity >=0.8.15;

interface IRateCalculator {
    function name() external pure returns (string memory);

    function requireValidInitData(bytes calldata _initData) external pure;

    function getConstants() external pure returns (bytes memory _calldata);

    function getNewRate(bytes calldata _data, bytes calldata _initData) external pure returns (uint64 _newRatePerSec);
}

// SPDX-License-Identifier: ISC
pragma solidity >=0.8.15;

interface IFraxlendWhitelist {
    function COMPTROLLER_ADDRESS() external view returns (address);

    function oracleContractWhitelist(address) external view returns (bool);

    function rateContractWhitelist(address) external view returns (bool);

    function fraxlendDeployerWhitelist(address) external view returns (bool);

    function setOracleContractWhitelist(address[] calldata _address, bool _bool) external;

    function setRateContractWhitelist(address[] calldata _address, bool _bool) external;

    function setFraxlendDeployerWhitelist(address[] calldata _address, bool _bool) external;
}

// SPDX-License-Identifier: ISC
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/interfaces/IERC20.sol";
import { SafeERC20 as OZSafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

// solhint-disable avoid-low-level-calls
// solhint-disable max-line-length

/// @title SafeERC20 provides helper functions for safe transfers as well as safe metadata access
/// @author Library originally written by @Boring_Crypto github.com/boring_crypto, modified by Drake Evans (Frax Finance) github.com/drakeevans
/// @dev original: https://github.com/boringcrypto/BoringSolidity/blob/fed25c5d43cb7ce20764cd0b838e21a02ea162e9/contracts/libraries/BoringERC20.sol
library SafeERC20 {
    bytes4 private constant SIG_SYMBOL = 0x95d89b41; // symbol()
    bytes4 private constant SIG_NAME = 0x06fdde03; // name()
    bytes4 private constant SIG_DECIMALS = 0x313ce567; // decimals()

    function returnDataToString(bytes memory data) internal pure returns (string memory) {
        if (data.length >= 64) {
            return abi.decode(data, (string));
        } else if (data.length == 32) {
            uint8 i = 0;
            while (i < 32 && data[i] != 0) {
                i++;
            }
            bytes memory bytesArray = new bytes(i);
            for (i = 0; i < 32 && data[i] != 0; i++) {
                bytesArray[i] = data[i];
            }
            return string(bytesArray);
        } else {
            return "???";
        }
    }

    /// @notice Provides a safe ERC20.symbol version which returns '???' as fallback string.
    /// @param token The address of the ERC-20 token contract.
    /// @return (string) Token symbol.
    function safeSymbol(IERC20 token) internal view returns (string memory) {
        (bool success, bytes memory data) = address(token).staticcall(abi.encodeWithSelector(SIG_SYMBOL));
        return success ? returnDataToString(data) : "???";
    }

    /// @notice Provides a safe ERC20.name version which returns '???' as fallback string.
    /// @param token The address of the ERC-20 token contract.
    /// @return (string) Token name.
    function safeName(IERC20 token) internal view returns (string memory) {
        (bool success, bytes memory data) = address(token).staticcall(abi.encodeWithSelector(SIG_NAME));
        return success ? returnDataToString(data) : "???";
    }

    /// @notice Provides a safe ERC20.decimals version which returns '18' as fallback value.
    /// @param token The address of the ERC-20 token contract.
    /// @return (uint8) Token decimals.
    function safeDecimals(IERC20 token) internal view returns (uint8) {
        (bool success, bytes memory data) = address(token).staticcall(abi.encodeWithSelector(SIG_DECIMALS));
        return success && data.length == 32 ? abi.decode(data, (uint8)) : 18;
    }

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        OZSafeERC20.safeTransfer(token, to, value);
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        OZSafeERC20.safeTransferFrom(token, from, to, value);
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

// SPDX-License-Identifier: ISC
pragma solidity ^0.8.15;

// ====================================================================
// |     ______                   _______                             |
// |    / _____________ __  __   / ____(_____  ____ _____  ________   |
// |   / /_  / ___/ __ `| |/_/  / /_  / / __ \/ __ `/ __ \/ ___/ _ \  |
// |  / __/ / /  / /_/ _>  <   / __/ / / / / / /_/ / / / / /__/  __/  |
// | /_/   /_/   \__,_/_/|_|  /_/   /_/_/ /_/\__,_/_/ /_/\___/\___/   |
// |                                                                  |
// ====================================================================
// ===================== FraxlendPairConstants ========================
// ====================================================================
// Frax Finance: https://github.com/FraxFinance

// Primary Author
// Drake Evans: https://github.com/DrakeEvans

// Reviewers
// Dennis Ettes: https://github.com/denett
// Sam Kazemian: https://github.com/samkazemian
// Travis Moore: https://github.com/FortisFortuna
// Jack Corddry: https://github.com/corddry
// Rich Gee: https://github.com/zer0blockchain

// ====================================================================

abstract contract FraxlendPairConstants {
    // ============================================================================================
    // Constants
    // ============================================================================================

    // Precision settings
    uint256 internal constant LTV_PRECISION = 1e5; // 5 decimals
    uint256 internal constant LIQ_PRECISION = 1e5;
    uint256 internal constant UTIL_PREC = 1e5;
    uint256 internal constant FEE_PRECISION = 1e5;
    uint256 internal constant EXCHANGE_PRECISION = 1e18;

    // Default Interest Rate (if borrows = 0)
    uint64 internal constant DEFAULT_INT = 158247046; // 0.5% annual rate

    // Dependencies
    address internal constant FRAXSWAP_ROUTER = 0xE52D0337904D4D0519EF7487e707268E1DB6495F;

    // Protocol Fee
    uint16 internal constant DEFAULT_PROTOCOL_FEE = 0;
    uint256 internal constant MAX_PROTOCOL_FEE = 5e4; // 50%

    error Insolvent(uint256 _borrow, uint256 _collateral, uint256 _exchangeRate);
    error BorrowerSolvent();
    error OnlyApprovedBorrowers();
    error OnlyApprovedLenders();
    error PastMaturity();
    error ProtocolOrOwnerOnly();
    error OracleLTEZero(address _oracle);
    error InsufficientAssetsInContract(uint256 _assets, uint256 _request);
    error NotOnWhitelist(address _address);
    error NotDeployer();
    error NameEmpty();
    error AlreadyInitialized();
    error SlippageTooHigh(uint256 _minOut, uint256 _actual);
    error BadSwapper();
    error InvalidPath(address _expected, address _actual);
    error BadProtocolFee();
    error ViolateMaxMintDeposit();
    error BorrowerWhitelistRequired();
}

// SPDX-License-Identifier: ISC
pragma solidity ^0.8.15;

// ====================================================================
// |     ______                   _______                             |
// |    / _____________ __  __   / ____(_____  ____ _____  ________   |
// |   / /_  / ___/ __ `| |/_/  / /_  / / __ \/ __ `/ __ \/ ___/ _ \  |
// |  / __/ / /  / /_/ _>  <   / __/ / / / / / /_/ / / / / /__/  __/  |
// | /_/   /_/   \__,_/_/|_|  /_/   /_/_/ /_/\__,_/_/ /_/\___/\___/   |
// |                                                                  |
// ====================================================================
// ========================= FraxlendPairCore =========================
// ====================================================================
// Frax Finance: https://github.com/FraxFinance

// Primary Author
// Drake Evans: https://github.com/DrakeEvans

// Reviewers
// Dennis Ettes: https://github.com/denett
// Sam Kazemian: https://github.com/samkazemian
// Travis Moore: https://github.com/FortisFortuna
// Jack Corddry: https://github.com/corddry
// Rich Gee: https://github.com/zer0blockchain

// ====================================================================

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "./FraxlendPairConstants.sol";
import "./libraries/VaultAccount.sol";
import "./libraries/SafeERC20.sol";
import "./interfaces/IERC4626.sol";
import "./interfaces/IFraxlendWhitelist.sol";
import "./interfaces/IRateCalculator.sol";
import "./interfaces/ISwapper.sol";

/// @title FraxlendPairCore
/// @author Drake Evans (Frax Finance) https://github.com/drakeevans
/// @notice  An abstract contract which contains the core logic and storage for the FraxlendPair
abstract contract FraxlendPairCore is FraxlendPairConstants, IERC4626, ERC20, Ownable, Pausable, ReentrancyGuard {
    using VaultAccountingLibrary for VaultAccount;
    using SafeERC20 for IERC20;

    string public version = "1.0.0";

    // ============================================================================================
    // Settings set by constructor() & initialize()
    // ============================================================================================

    // Asset and collateral contracts
    IERC20 internal immutable assetContract;
    IERC20 public immutable collateralContract;

    // Oracle wrapper contract and oracleData
    address public immutable oracleMultiply;
    address public immutable oracleDivide;
    uint256 public immutable oracleNormalization;

    // LTV Settings
    uint256 public immutable maxLTV;

    // Liquidation Fee
    uint256 public immutable liquidationFee;

    // Interest Rate Calculator Contract
    IRateCalculator public immutable rateContract; // For complex rate calculations
    bytes public rateInitCallData; // Optional extra data from init function to be passed to rate calculator

    // Swapper
    mapping(address => bool) public swappers; // approved swapper addresses

    // Deployer
    address public immutable DEPLOYER_CONTRACT;

    // Admin contracts
    address public immutable CIRCUIT_BREAKER;
    address public immutable COMPTROLLER_ADDRESS;

    // Dependencies
    address public immutable FRAXLEND_WHITELIST;

    // ERC20 token name, accessible via name()
    string internal nameOfContract;

    // Maturity Date & Penalty Interest Rate (per Sec)
    uint256 public immutable maturity;
    uint256 public immutable penaltyRate;

    // ============================================================================================
    // Storage
    // ============================================================================================

    /// @notice Stores information about the current interest rate
    /// @dev struct is packed to reduce SLOADs. feeToProtocolRate is 1e5 precision, ratePerSec is 1e18 precision
    CurrentRateInfo public currentRateInfo;
    struct CurrentRateInfo {
        uint16 lastBlock;
        uint16 feeToProtocolRate; // Fee amount 1e5 precision
        uint32 lastTimestamp;
        uint64 ratePerSec;
    }

    /// @notice Stores information about the current exchange rate. Collateral:Asset ratio
    /// @dev Struct packed to save SLOADs. Amount of Collateral Token to buy 1e18 Asset Token
    ExchangeRateInfo public exchangeRateInfo;
    struct ExchangeRateInfo {
        uint32 lastTimestamp;
        uint224 exchangeRate; // collateral:asset ratio. i.e. how much collateral to buy 1e18 asset
    }

    // Contract Level Accounting
    VaultAccount public totalAsset; // amount = total amount of assets, shares = total shares outstanding
    VaultAccount public totalBorrow; // amount = total borrow amount with interest accrued, shares = total shares outstanding
    uint256 public totalCollateral; // total amount of collateral in contract

    // User Level Accounting
    /// @notice Stores the balance of collateral for each user
    mapping(address => uint256) public userCollateralBalance; // amount of collateral each user is backed
    /// @notice Stores the balance of borrow shares for each user
    mapping(address => uint256) public userBorrowShares; // represents the shares held by individuals
    // NOTE: user shares of assets are represented as ERC-20 tokens and accessible via balanceOf()

    // Internal Whitelists
    bool public immutable borrowerWhitelistActive;
    mapping(address => bool) public approvedBorrowers;
    bool public immutable lenderWhitelistActive;
    mapping(address => bool) public approvedLenders;

    // ============================================================================================
    // Initialize
    // ============================================================================================

    /// @notice The ```constructor``` function is called on deployment
    /// @param _configData abi.encode(address _asset, address _collateral, address _oracleMultiply, address _oracleDivide, uint256 _oracleNormalization, address _rateContract, bytes memory _rateInitData)
    /// @param _maxLTV The Maximum Loan-To-Value for a borrower to be considered solvent (1e5 precision)
    /// @param _liquidationFee The fee paid to liquidators given as a % of the repayment (1e5 precision)
    /// @param _maturity The maturity date of the Pair
    /// @param _penaltyRate The interest rate after maturity date
    /// @param _isBorrowerWhitelistActive Enables borrower whitelist
    /// @param _isLenderWhitelistActive Enables lender whitelist
    constructor(
        bytes memory _configData,
        bytes memory _immutables,
        uint256 _maxLTV,
        uint256 _liquidationFee,
        uint256 _maturity,
        uint256 _penaltyRate,
        bool _isBorrowerWhitelistActive,
        bool _isLenderWhitelistActive
    ) {
        (
            address _asset,
            address _collateral,
            address _oracleMultiply,
            address _oracleDivide,
            uint256 _oracleNormalization,
            address _rateContract,

        ) = abi.decode(_configData, (address, address, address, address, uint256, address, bytes));

        (address _circuitBreaker, address _comptrollerAddress, address _fraxlendWhitelistAddress) = abi.decode(
            _immutables,
            (address, address, address)
        );

        // Deployer contract
        DEPLOYER_CONTRACT = msg.sender;
        CIRCUIT_BREAKER = _circuitBreaker;
        COMPTROLLER_ADDRESS = _comptrollerAddress;
        FRAXLEND_WHITELIST = _fraxlendWhitelistAddress;

        // Pair Settings
        assetContract = IERC20(_asset);
        collateralContract = IERC20(_collateral);
        currentRateInfo.feeToProtocolRate = DEFAULT_PROTOCOL_FEE;
        liquidationFee = _liquidationFee;

        if (_maxLTV >= LTV_PRECISION && !_isBorrowerWhitelistActive) revert BorrowerWhitelistRequired();
        maxLTV = _maxLTV;

        // Swapper Settings
        swappers[FRAXSWAP_ROUTER] = true;

        // Oracle Settings
        IFraxlendWhitelist _fraxlendWhitelist = IFraxlendWhitelist(FRAXLEND_WHITELIST);
        // Check that oracles are on the whitelist
        if (_oracleMultiply != address(0) && !_fraxlendWhitelist.oracleContractWhitelist(_oracleMultiply)) {
            revert NotOnWhitelist(_oracleMultiply);
        }

        if (_oracleDivide != address(0) && !_fraxlendWhitelist.oracleContractWhitelist(_oracleDivide)) {
            revert NotOnWhitelist(_oracleDivide);
        }

        // Write oracleData to storage
        oracleMultiply = _oracleMultiply;
        oracleDivide = _oracleDivide;
        oracleNormalization = _oracleNormalization;

        // Rate Settings
        if (!_fraxlendWhitelist.rateContractWhitelist(_rateContract)) {
            revert NotOnWhitelist(_rateContract);
        }
        rateContract = IRateCalculator(_rateContract);

        // Set approved borrowers whitelist
        borrowerWhitelistActive = _isBorrowerWhitelistActive;

        // Set approved lenders whitlist active
        lenderWhitelistActive = _isLenderWhitelistActive;

        // Set maturity date & penalty interest rate
        maturity = _maturity;
        penaltyRate = _penaltyRate;

        // Transfer ownership to comptroller
        _transferOwnership(COMPTROLLER_ADDRESS);
    }

    /// @notice The ```initialize``` function is called immediately after deployment
    /// @dev This function can only be called by the deployer
    /// @param _name The name of the contract
    /// @param _approvedBorrowers An array of approved borrower addresses
    /// @param _approvedLenders An array of approved lender addresses
    /// @param _rateInitCallData The configuration data for the Rate Calculator contract
    function initialize(
        string calldata _name,
        address[] calldata _approvedBorrowers,
        address[] calldata _approvedLenders,
        bytes calldata _rateInitCallData
    ) external {
        if (msg.sender != DEPLOYER_CONTRACT) {
            revert NotDeployer();
        }
        if (bytes(_name).length == 0) {
            revert NameEmpty();
        }
        if (bytes(nameOfContract).length != 0) {
            revert AlreadyInitialized();
        }

        // Set name
        nameOfContract = _name;

        // Set approved borrowers
        for (uint256 i = 0; i < _approvedBorrowers.length; ++i) {
            approvedBorrowers[_approvedBorrowers[i]] = true;
        }

        // Set approved lenders
        for (uint256 i = 0; i < _approvedLenders.length; ++i) {
            approvedLenders[_approvedLenders[i]] = true;
        }

        // Reverts if init data is not valid
        IRateCalculator(rateContract).requireValidInitData(_rateInitCallData);

        // Set rate init Data
        rateInitCallData = _rateInitCallData;

        // Instantiate Interest
        _addInterest();

        // Instantiate Exchange Rate
        _updateExchangeRate();
    }

    // ============================================================================================
    // Internal Helpers
    // ============================================================================================

    /// @notice The ```_totalAssetAvailable``` function returns the total balance of Asset Tokens in the contract
    /// @param _totalAsset VaultAccount struct which stores total amount and shares for assets
    /// @param _totalBorrow VaultAccount struct which stores total amount and shares for borrows
    /// @return The balance of Asset Tokens held by contract
    function _totalAssetAvailable(VaultAccount memory _totalAsset, VaultAccount memory _totalBorrow)
        internal
        pure
        returns (uint256)
    {
        return _totalAsset.amount - _totalBorrow.amount;
    }

    /// @notice The ```_isSolvent``` function determines if a given borrower is solvent given an exchange rate
    /// @param _borrower The borrower address to check
    /// @param _exchangeRate The exchange rate, i.e. the amount of collateral to buy 1e18 asset
    /// @return Whether borrower is solvent
    function _isSolvent(address _borrower, uint256 _exchangeRate) internal view returns (bool) {
        if (maxLTV == 0) return true;
        uint256 _borrowerAmount = totalBorrow.toAmount(userBorrowShares[_borrower], true);
        if (_borrowerAmount == 0) return true;
        uint256 _collateralAmount = userCollateralBalance[_borrower];
        if (_collateralAmount == 0) return false;

        uint256 _ltv = (_borrowerAmount * _exchangeRate * LTV_PRECISION) / (_collateralAmount * EXCHANGE_PRECISION);
        return _ltv <= maxLTV;
    }

    /// @notice The ```_isPastMaturity``` function determines if the current block timestamp is past the maturity date
    /// @return Whether or not the debt is past maturity
    function _isPastMaturity() internal view returns (bool) {
        return maturity != 0 && block.timestamp > maturity;
    }

    // ============================================================================================
    // Modifiers
    // ============================================================================================

    /// @notice Checks for solvency AFTER executing contract code
    /// @param _borrower The borrower whose solvency we will check
    modifier isSolvent(address _borrower) {
        _;
        if (!_isSolvent(_borrower, exchangeRateInfo.exchangeRate)) {
            revert Insolvent(balanceOf(_borrower), userCollateralBalance[_borrower], exchangeRateInfo.exchangeRate);
        }
    }

    /// @notice Checks if msg.sender is an approved Borrower
    modifier approvedBorrower() {
        if (borrowerWhitelistActive && !approvedBorrowers[msg.sender]) {
            revert OnlyApprovedBorrowers();
        }
        _;
    }

    /// @notice Checks if msg.sender and _receiver are both an approved Lender
    /// @param _receiver An additional receiver address to check
    modifier approvedLender(address _receiver) {
        if (lenderWhitelistActive && (!approvedLenders[msg.sender] || !approvedLenders[_receiver])) {
            revert OnlyApprovedLenders();
        }
        _;
    }

    modifier notPassedMaturity() {
        if (_isPastMaturity()) {
            revert PastMaturity();
        }
        _;
    }

    // ============================================================================================
    // Functions: Interest Accumulation and Adjustment
    // ============================================================================================

    /// @notice The ```AddInterest``` event is emitted when interest is accrued by borrowers
    /// @param _interestEarned The total interest accrued by all borrowers
    /// @param _rate The interest rate used to calculate accrued interest
    /// @param _deltaTime The time elapsed since last interest accrual
    /// @param _feesAmount The amount of fees paid to protocol
    /// @param _feesShare The amount of shares distributed to protocol
    event AddInterest(
        uint256 _interestEarned,
        uint256 _rate,
        uint256 _deltaTime,
        uint256 _feesAmount,
        uint256 _feesShare
    );

    /// @notice The ```UpdateRate``` event is emitted when the interest rate is updated
    /// @param _ratePerSec The old interest rate (per second)
    /// @param _deltaTime The time elapsed since last update
    /// @param _utilizationRate The utilization of assets in the Pair
    /// @param _newRatePerSec The new interest rate (per second)
    event UpdateRate(uint256 _ratePerSec, uint256 _deltaTime, uint256 _utilizationRate, uint256 _newRatePerSec);

    /// @notice The ```addInterest``` function is a public implementation of _addInterest and allows 3rd parties to trigger interest accrual
    /// @return _interestEarned The amount of interest accrued by all borrowers
    function addInterest() external nonReentrant returns (uint256 _interestEarned) {
        return _addInterest();
    }

    /// @notice The ```_addInterest``` function is invoked prior to every external function and is used to accrue interest and update interest rate
    /// @dev Can only called once per block
    /// @return _interestEarned The amount of interest accrued by all borrowers
    function _addInterest() internal returns (uint256 _interestEarned) {
        // Add interest only once per block
        CurrentRateInfo memory _currentRateInfo = currentRateInfo;
        if (_currentRateInfo.lastTimestamp == block.timestamp) return 0;

        // Pull some data from storage to save gas
        VaultAccount memory _totalAsset = totalAsset;
        VaultAccount memory _totalBorrow = totalBorrow;

        // If there are no borrows, no interest accrues
        if (_totalBorrow.shares == 0 || paused()) {
            if (!paused()) {
                _currentRateInfo.ratePerSec = DEFAULT_INT;
            }
            _currentRateInfo.lastTimestamp = uint32(block.timestamp);
            _currentRateInfo.lastBlock = uint16(block.number);

            // Effects: write to storage
            currentRateInfo = _currentRateInfo;
        } else {
            // We know totalBorrow.shares > 0
            uint256 _deltaTime = block.timestamp - _currentRateInfo.lastTimestamp;

            // NOTE: Violates Checks-Effects-Interactions pattern
            // Be sure to mark external version NONREENTRANT (even though rateContract is trusted)
            // Calc new rate
            uint256 _utilizationRate = (_totalBorrow.amount * UTIL_PREC) / _totalAsset.amount;
            uint64 _newRate;
            if (_isPastMaturity()) {
                _newRate = uint64(penaltyRate);
            } else {
                bytes memory _rateData = abi.encode(
                    _currentRateInfo.ratePerSec,
                    _deltaTime,
                    _utilizationRate,
                    block.number - currentRateInfo.lastBlock
                );
                _newRate = IRateCalculator(rateContract).getNewRate(_rateData, rateInitCallData);
            }

            // Event must be here to use non-mutated values
            emit UpdateRate(_currentRateInfo.ratePerSec, _deltaTime, _utilizationRate, _newRate);

            // Effects: bookkeeping
            _currentRateInfo.ratePerSec = _newRate;
            _currentRateInfo.lastTimestamp = uint32(block.timestamp);
            _currentRateInfo.lastBlock = uint16(block.number);

            // Calculate interest accrued
            _interestEarned = (_totalBorrow.amount * _currentRateInfo.ratePerSec * _deltaTime) / 1e18;

            // recapitalizes interest accrued, only if no overflow
            if (_interestEarned + _totalBorrow.amount <= type(uint128).max) {
                _totalBorrow.amount += uint128(_interestEarned);
            }
            if (_interestEarned + _totalAsset.amount <= type(uint128).max) {
                _totalAsset.amount += uint128(_interestEarned);
            }

            uint256 _feesAmount = 0;
            uint256 _feesShare = 0;
            if (_currentRateInfo.feeToProtocolRate > 0) {
                _feesAmount = (_interestEarned * _currentRateInfo.feeToProtocolRate) / FEE_PRECISION;

                _feesShare = (_feesAmount * _totalAsset.shares) / (_totalAsset.amount - _feesAmount);

                // Effects: Give new shares to this contract effectively diluting lenders an amount equal to the fees
                _totalAsset.shares += uint128(_feesShare);

                // Effects: write to storage
                _mint(address(this), _feesShare);
            }
            emit AddInterest(_interestEarned, _currentRateInfo.ratePerSec, _deltaTime, _feesAmount, _feesShare);

            // Effects: write to storage
            totalAsset = _totalAsset;
            currentRateInfo = _currentRateInfo;
            totalBorrow = _totalBorrow;
        }
    }

    // ============================================================================================
    // Functions: ExchangeRate
    // ============================================================================================
    /// @notice The ```UpdateExchangeRate``` event is emitted when the Collateral:Asset exchange rate is updated
    /// @param _rate The new rate given as the amount of Collateral Token to buy 1e18 Asset Token
    event UpdateExchangeRate(uint256 _rate);

    /// @notice The ```updateExchangeRate``` function is the external implementation of _updateExchangeRate.
    /// @dev This function is invoked at most once per block as these queries can be expensive
    /// @return _exchangeRate The new exchange rate
    function updateExchangeRate() external nonReentrant returns (uint256 _exchangeRate) {
        _exchangeRate = _updateExchangeRate();
    }

    /// @notice The ```_updateExchangeRate``` function retrieves the latest exchange rate. i.e how much collateral to buy 1e18 asset.
    /// @dev This function is invoked at most once per block as these queries can be expensive
    /// @return _exchangeRate The new exchange rate
    function _updateExchangeRate() internal returns (uint256 _exchangeRate) {
        ExchangeRateInfo memory _exchangeRateInfo = exchangeRateInfo;
        if (_exchangeRateInfo.lastTimestamp == block.timestamp) {
            return _exchangeRate = _exchangeRateInfo.exchangeRate;
        }

        uint256 _price = uint256(1e36);
        if (oracleMultiply != address(0)) {
            (, int256 _answer, , , ) = AggregatorV3Interface(oracleMultiply).latestRoundData();
            if (_answer <= 0) {
                revert OracleLTEZero(oracleMultiply);
            }
            _price = _price * uint256(_answer);
        }

        if (oracleDivide != address(0)) {
            (, int256 _answer, , , ) = AggregatorV3Interface(oracleDivide).latestRoundData();
            if (_answer <= 0) {
                revert OracleLTEZero(oracleDivide);
            }
            _price = _price / uint256(_answer);
        }

        _exchangeRate = _price / oracleNormalization;

        // write to storage
        _exchangeRateInfo.exchangeRate = uint224(_exchangeRate);
        _exchangeRateInfo.lastTimestamp = uint32(block.timestamp);
        exchangeRateInfo = _exchangeRateInfo;
        emit UpdateExchangeRate(_exchangeRate);
    }

    // ============================================================================================
    // Functions: Lending
    // ============================================================================================

    /// @notice The ```_deposit``` function is the internal implementation for lending assets
    /// @dev Caller must invoke ```ERC20.approve``` on the Asset Token contract prior to calling function
    /// @param _totalAsset An in memory VaultAccount struct representing the total amounts and shares for the Asset Token
    /// @param _amount The amount of Asset Token to be transferred
    /// @param _shares The amount of Asset Shares (fTokens) to be minted
    /// @param _receiver The address to receive the Asset Shares (fTokens)
    function _deposit(
        VaultAccount memory _totalAsset,
        uint128 _amount,
        uint128 _shares,
        address _receiver
    ) internal {
        // Effects: bookkeeping
        _totalAsset.amount += _amount;
        _totalAsset.shares += _shares;

        // Effects: write back to storage
        _mint(_receiver, _shares);
        totalAsset = _totalAsset;

        // Interactions
        assetContract.safeTransferFrom(msg.sender, address(this), _amount);
        emit Deposit(msg.sender, _receiver, _amount, _shares);
    }

    /// @notice The ```deposit``` function allows a user to Lend Assets by specifying the amount of Asset Tokens to lend
    /// @dev Caller must invoke ```ERC20.approve``` on the Asset Token contract prior to calling function
    /// @param _amount The amount of Asset Token to transfer to Pair
    /// @param _receiver The address to receive the Asset Shares (fTokens)
    /// @return _sharesReceived The number of fTokens received for the deposit
    function deposit(uint256 _amount, address _receiver)
        external
        nonReentrant
        notPassedMaturity
        whenNotPaused
        approvedLender(_receiver)
        returns (uint256 _sharesReceived)
    {
        if (_amount >= type(uint128).max) revert ViolateMaxMintDeposit();
        _addInterest();
        VaultAccount memory _totalAsset = totalAsset;
        _sharesReceived = _totalAsset.toShares(_amount, false);
        _deposit(_totalAsset, uint128(_amount), uint128(_sharesReceived), _receiver);
    }

    /// @notice The ```mint``` function allows a user to Lend assets by specifying the number of Assets Shares (fTokens) to mint
    /// @dev Caller must invoke ```ERC20.approve``` on the Asset Token contract prior to calling function
    /// @param _shares The number of Asset Shares (fTokens) that a user wants to mint
    /// @param _receiver The address to receive the Asset Shares (fTokens)
    /// @return _amountReceived The amount of Asset Tokens transferred to the Pair
    function mint(uint256 _shares, address _receiver)
        external
        nonReentrant
        notPassedMaturity
        whenNotPaused
        approvedLender(_receiver)
        returns (uint256 _amountReceived)
    {
        if (_shares >= type(uint128).max) revert ViolateMaxMintDeposit();
        _addInterest();
        VaultAccount memory _totalAsset = totalAsset;
        _amountReceived = _totalAsset.toAmount(_shares, true);
        _deposit(_totalAsset, uint128(_amountReceived), uint128(_shares), _receiver);
    }

    /// @notice The ```_redeem``` function is an internal implementation which allows a Lender to pull their Asset Tokens out of the Pair
    /// @dev Caller must invoke ```ERC20.approve``` on the Asset Token contract prior to calling function
    /// @param _totalAsset An in-memory VaultAccount struct which holds the total amount of Asset Tokens and the total number of Asset Shares (fTokens)
    /// @param _amountToReturn The number of Asset Tokens to return
    /// @param _shares The number of Asset Shares (fTokens) to burn
    /// @param _receiver The address to which the Asset Tokens will be transferred
    /// @param _owner The owner of the Asset Shares (fTokens)
    function _redeem(
        VaultAccount memory _totalAsset,
        uint256 _amountToReturn,
        uint256 _shares,
        address _receiver,
        address _owner
    ) internal {
        if (msg.sender != _owner) {
            uint256 allowed = allowance(_owner, msg.sender);
            // NOTE: This will revert on underflow ensuring that allowance > shares
            if (allowed != type(uint256).max) _approve(_owner, msg.sender, allowed - _shares);
        }

        // Check for sufficient withdraw liquidity
        uint256 _assetsAvailable = _totalAssetAvailable(_totalAsset, totalBorrow);
        if (_assetsAvailable < _amountToReturn) {
            revert InsufficientAssetsInContract(_assetsAvailable, _amountToReturn);
        }

        // Effects: bookkeeping
        _totalAsset.amount -= uint128(_amountToReturn);
        _totalAsset.shares -= uint128(_shares);

        // Effects: write to storage
        totalAsset = _totalAsset;
        _burn(_owner, _shares);

        // Interactions
        assetContract.safeTransfer(_receiver, _amountToReturn);
        emit Withdraw(msg.sender, _receiver, _owner, _amountToReturn, _shares);
    }

    /// @notice The ```redeem``` function allows the caller to redeem their Asset Shares for Asset Tokens
    /// @param _shares The number of Asset Shares (fTokens) to burn for Asset Tokens
    /// @param _receiver The address to which the Asset Tokens will be transferred
    /// @param _owner The owner of the Asset Shares (fTokens)
    /// @return _amountToReturn The amount of Asset Tokens to be transferred
    function redeem(
        uint256 _shares,
        address _receiver,
        address _owner
    ) external nonReentrant returns (uint256 _amountToReturn) {
        _addInterest();
        VaultAccount memory _totalAsset = totalAsset;
        _amountToReturn = _totalAsset.toAmount(_shares, false);
        _redeem(_totalAsset, _amountToReturn, _shares, _receiver, _owner);
    }

    /// @notice The ```withdraw``` function allows a user to redeem their Asset Shares for a specified amount of Asset Tokens
    /// @param _amount The amount of Asset Tokens to be transferred in exchange for burning Asset Shares
    /// @param _receiver The address to which the Asset Tokens will be transferred
    /// @param _owner The owner of the Asset Shares (fTokens)
    /// @return _shares The number of Asset Shares (fTokens) burned
    function withdraw(
        uint256 _amount,
        address _receiver,
        address _owner
    ) external nonReentrant returns (uint256 _shares) {
        _addInterest();
        VaultAccount memory _totalAsset = totalAsset;
        _shares = _totalAsset.toShares(_amount, true);
        _redeem(_totalAsset, _amount, _shares, _receiver, _owner);
    }

    // ============================================================================================
    // Functions: Borrowing
    // ============================================================================================

    /// @notice The ```BorrowAsset``` event is emitted when a borrower increases their position
    /// @param _borrower The borrower whose account was debited
    /// @param _receiver The address to which the Asset Tokens were transferred
    /// @param _borrowAmount The amount of Asset Tokens transferred
    /// @param _sharesAdded The number of Borrow Shares the borrower was debited
    event BorrowAsset(
        address indexed _borrower,
        address indexed _receiver,
        uint256 _borrowAmount,
        uint256 _sharesAdded
    );

    /// @notice The ```_borrowAsset``` function is the internal implementation for borrowing assets
    /// @param _borrowAmount The amount of the Asset Token to borrow
    /// @param _receiver The address to receive the Asset Tokens
    /// @return _sharesAdded The amount of borrow shares the msg.sender will be debited
    function _borrowAsset(uint256 _borrowAmount, address _receiver) internal returns (uint256 _sharesAdded) {
        VaultAccount memory _totalBorrow = totalBorrow;

        // Check available capital
        uint256 _assetsAvailable = _totalAssetAvailable(totalAsset, _totalBorrow);
        if (_assetsAvailable < _borrowAmount) {
            revert InsufficientAssetsInContract(_assetsAvailable, _borrowAmount);
        }

        // Effects: Bookkeeping to add shares & amounts to total Borrow accounting
        _sharesAdded = _totalBorrow.toShares(_borrowAmount, true);
        _totalBorrow.amount += uint128(_borrowAmount);
        _totalBorrow.shares += uint128(_sharesAdded);

        // Effects: write back to storage
        totalBorrow = _totalBorrow;
        userBorrowShares[msg.sender] += _sharesAdded;

        // Interactions
        if (_receiver != address(this)) {
            assetContract.safeTransfer(_receiver, _borrowAmount);
        }
        emit BorrowAsset(msg.sender, _receiver, _borrowAmount, _sharesAdded);
    }

    /// @notice The ```borrowAsset``` function allows a user to open/increase a borrow position
    /// @dev Borrower must call ```ERC20.approve``` on the Collateral Token contract if applicable
    /// @param _borrowAmount The amount of Asset Token to borrow
    /// @param _collateralAmount The amount of Collateral Token to transfer to Pair
    /// @param _receiver The address which will receive the Asset Tokens
    /// @return _shares The number of borrow Shares the msg.sender will be debited
    function borrowAsset(
        uint256 _borrowAmount,
        uint256 _collateralAmount,
        address _receiver
    )
        external
        notPassedMaturity
        whenNotPaused
        nonReentrant
        isSolvent(msg.sender)
        approvedBorrower
        returns (uint256 _shares)
    {
        _addInterest();
        _updateExchangeRate();
        if (_collateralAmount > 0) {
            _addCollateral(msg.sender, _collateralAmount, msg.sender);
        }
        _shares = _borrowAsset(_borrowAmount, _receiver);
    }

    event AddCollateral(address indexed _sender, address indexed _borrower, uint256 _collateralAmount);

    /// @notice The ```_addCollateral``` function is an internal implementation for adding collateral to a borrowers position
    /// @param _sender The source of funds for the new collateral
    /// @param _collateralAmount The amount of Collateral Token to be transferred
    /// @param _borrower The borrower account for which the collateral should be credited
    function _addCollateral(
        address _sender,
        uint256 _collateralAmount,
        address _borrower
    ) internal {
        // Effects: write to state
        userCollateralBalance[_borrower] += _collateralAmount;
        totalCollateral += _collateralAmount;

        // Interactions
        if (_sender != address(this)) {
            collateralContract.safeTransferFrom(_sender, address(this), _collateralAmount);
        }
        emit AddCollateral(_sender, _borrower, _collateralAmount);
    }

    /// @notice The ```addCollateral``` function allows the caller to add Collateral Token to a borrowers position
    /// @dev msg.sender must call ERC20.approve() on the Collateral Token contract prior to invocation
    /// @param _collateralAmount The amount of Collateral Token to be added to borrower's position
    /// @param _borrower The account to be credited
    function addCollateral(uint256 _collateralAmount, address _borrower) external nonReentrant notPassedMaturity {
        _addInterest();
        _addCollateral(msg.sender, _collateralAmount, _borrower);
    }

    /// @notice The ```RemoveCollateral``` event is emitted when collateral is removed from a borrower's position
    /// @param _sender The account from which funds are transferred
    /// @param _collateralAmount The amount of Collateral Token to be transferred
    /// @param _receiver The address to which Collateral Tokens will be transferred
    event RemoveCollateral(
        address indexed _sender,
        uint256 _collateralAmount,
        address indexed _receiver,
        address indexed _borrower
    );

    /// @notice The ```_removeCollateral``` function is the internal implementation for removing collateral from a borrower's position
    /// @param _collateralAmount The amount of Collateral Token to remove from the borrower's position
    /// @param _receiver The address to receive the Collateral Token transferred
    /// @param _borrower The borrower whose account will be debited the Collateral amount
    function _removeCollateral(
        uint256 _collateralAmount,
        address _receiver,
        address _borrower
    ) internal {
        // Effects: write to state
        // Following line will revert on underflow if _collateralAmount > userCollateralBalance
        userCollateralBalance[_borrower] -= _collateralAmount;
        // Following line will revert on underflow if totalCollateral < _collateralAmount
        totalCollateral -= _collateralAmount;

        // Interactions
        if (_receiver != address(this)) {
            collateralContract.safeTransfer(_receiver, _collateralAmount);
        }
        emit RemoveCollateral(msg.sender, _collateralAmount, _receiver, _borrower);
    }

    /// @notice The ```removeCollateral``` function is used to remove collateral from msg.sender's borrow position
    /// @dev msg.sender must be solvent after invocation or transaction will revert
    /// @param _collateralAmount The amount of Collateral Token to transfer
    /// @param _receiver The address to receive the transferred funds
    function removeCollateral(uint256 _collateralAmount, address _receiver)
        external
        nonReentrant
        isSolvent(msg.sender)
    {
        _addInterest();
        _updateExchangeRate();
        _removeCollateral(_collateralAmount, _receiver, msg.sender);
    }

    /// @notice The ```RepayAsset``` event is emitted whenever a debt position is repaid
    /// @param _sender The msg.sender of the transaction
    /// @param _borrower The borrower whose account will be credited
    /// @param _amountToRepay The amount of Asset token to be transferred
    /// @param _shares The amount of Borrow Shares which will be debited from the borrower after repayment
    event RepayAsset(address indexed _sender, address indexed _borrower, uint256 _amountToRepay, uint256 _shares);

    /// @notice The ```_repayAsset``` function is the internal implementation for repaying a borrow position
    /// @dev The payer must have called ERC20.approve() on the Asset Token contract prior to invocation
    /// @param _totalBorrow An in memory copy of the totalBorrow VaultAccount struct
    /// @param _amountToRepay The amount of Asset Token to transfer
    /// @param _shares The number of Borrow Shares the sender is repaying
    /// @param _payer The address from which funds will be transferred
    /// @param _borrower The borrower account which will be credited
    function _repayAsset(
        VaultAccount memory _totalBorrow,
        uint256 _amountToRepay,
        uint256 _shares,
        address _payer,
        address _borrower
    ) internal {
        // Effects: Bookkeeping
        _totalBorrow.amount -= uint128(_amountToRepay);
        _totalBorrow.shares -= uint128(_shares);

        // Effects: write to state
        userBorrowShares[_borrower] -= _shares;
        totalBorrow = _totalBorrow;

        // Interactions
        if (_payer != address(this)) {
            assetContract.safeTransferFrom(_payer, address(this), _amountToRepay);
        }
        emit RepayAsset(msg.sender, _borrower, _amountToRepay, _shares);
    }

    /// @notice The ```repayAsset``` function allows the caller to pay down the debt for a given borrower.
    /// @dev Caller must first invoke ```ERC20.approve()``` for the Asset Token contract
    /// @param _shares The number of Borrow Shares which will be repaid by the call
    /// @param _borrower The account for which the debt will be reduced
    /// @return _amountToRepay The amount of Asset Tokens which were transferred in order to repay the Borrow Shares
    function repayAsset(uint256 _shares, address _borrower) external nonReentrant returns (uint256 _amountToRepay) {
        _addInterest();
        VaultAccount memory _totalBorrow = totalBorrow;
        _amountToRepay = _totalBorrow.toAmount(_shares, true);

        _repayAsset(_totalBorrow, _amountToRepay, _shares, msg.sender, _borrower);
    }

    // ============================================================================================
    // Functions: Liquidations
    // ============================================================================================
    /// @notice The ```Liquidate``` event is emitted when a liquidation occurs
    /// @param _borrower The borrower account for which the liquidation occured
    /// @param _collateralForLiquidator The amount of Collateral Token transferred to the liquidator
    /// @param _shares The number of Borrow Shares the liquidator repaid on behalf of the borrower
    event Liquidate(address indexed _borrower, uint256 _collateralForLiquidator, uint256 _shares);

    /// @notice The ```liquidate``` function allows a third party to repay a borrower's debt if they have become insolvent
    /// @dev Caller must invoke ```ERC20.approve``` on the Asset Token contract prior to calling ```Liquidate()```
    /// @param _shares The number of Borrow Shares repaid by the liquidator
    /// @param _borrower The account for which the repayment is credited and from whom collateral will be taken
    /// @return _collateralForLiquidator The amount of Collateral Token transferred to the liquidator
    function liquidate(uint256 _shares, address _borrower)
        external
        whenNotPaused
        nonReentrant
        approvedLender(msg.sender)
        returns (uint256 _collateralForLiquidator)
    {
        _addInterest();

        // Get best available exchange rate
        uint256 _exchangeRate = _updateExchangeRate();
        if (_isSolvent(_borrower, _exchangeRate)) {
            revert BorrowerSolvent();
        }

        VaultAccount memory _totalBorrow = totalBorrow;

        // Determine how much of the borrow and collateral will be repaid
        _collateralForLiquidator =
            (_totalBorrow.toAmount(_shares, false) * _exchangeRate * (LIQ_PRECISION + liquidationFee)) /
            (LIQ_PRECISION * EXCHANGE_PRECISION);

        // Effects & Interactions
        // NOTE: reverts if _shares > userBorrowShares
        uint256 _amountToRepay = _totalBorrow.toAmount(_shares, true);
        _repayAsset(_totalBorrow, _amountToRepay, _shares, msg.sender, _borrower); // liquidator repays shares on behalf of borrower
        // NOTE: reverts if _collateralForLiquidator > userCollateralBalance
        // Collateral is removed on behalf of borrower and sent to liquidator
        _removeCollateral(_collateralForLiquidator, msg.sender, _borrower);
        emit Liquidate(_borrower, _collateralForLiquidator, _shares);
    }

    // ============================================================================================
    // Functions: Leverage
    // ============================================================================================

    /// @notice The ```LeveragedPosition``` event is emitted when a borrower takes out a new leveraged position
    /// @param _borrower The account for which the debt is debited
    /// @param _swapperAddress The address of the swapper which conforms the FraxSwap interface
    /// @param _borrowAmount The amount of Asset Token to be borrowed to be borrowed
    /// @param _borrowShares The number of Borrow Shares the borrower is credited
    /// @param _initialCollateralAmount The amount of initial Collateral Tokens supplied by the borrower
    /// @param _amountCollateralOut The amount of Collateral Token which was received for the Asset Tokens
    event LeveragedPosition(
        address indexed _borrower,
        address _swapperAddress,
        uint256 _borrowAmount,
        uint256 _borrowShares,
        uint256 _initialCollateralAmount,
        uint256 _amountCollateralOut
    );

    /// @notice The ```leveragedPosition``` function allows a user to enter a leveraged borrow position with minimal upfront Collateral
    /// @dev Caller must invoke ```ERC20.approve()``` on the Collateral Token contract prior to calling function
    /// @param _swapperAddress The address of the whitelisted swapper to use to swap borrowed Asset Tokens for Collateral Tokens
    /// @param _borrowAmount The amount of Asset Tokens borrowed
    /// @param _initialCollateralAmount The initial amount of Collateral Tokens supplied by the borrower
    /// @param _amountCollateralOutMin The minimum amount of Collateral Tokens to be received in exchange for the borrowed Asset Tokens
    /// @param _path An array containing the addresses of ERC20 tokens to swap.  Adheres to UniV2 style path params.
    /// @return _totalCollateralBalance The total amount of Collateral Tokens added to a users account (initial + swap)
    function leveragedPosition(
        address _swapperAddress,
        uint256 _borrowAmount,
        uint256 _initialCollateralAmount,
        uint256 _amountCollateralOutMin,
        address[] memory _path
    )
        external
        notPassedMaturity
        whenNotPaused
        nonReentrant
        approvedBorrower
        isSolvent(msg.sender)
        returns (uint256 _totalCollateralBalance)
    {
        _addInterest();
        _updateExchangeRate();

        IERC20 _assetContract = assetContract;
        IERC20 _collateralContract = collateralContract;

        if (!swappers[_swapperAddress]) {
            revert BadSwapper();
        }
        if (_path[0] != address(_assetContract)) {
            revert InvalidPath(address(_assetContract), _path[0]);
        }
        if (_path[_path.length - 1] != address(_collateralContract)) {
            revert InvalidPath(address(_collateralContract), _path[_path.length - 1]);
        }

        // Add initial collateral
        _addCollateral(msg.sender, _initialCollateralAmount, msg.sender);

        // Debit borrowers account
        // setting recipient to address(this) means no transfer will happen
        uint256 _borrowShares = _borrowAsset(_borrowAmount, address(this));

        // Interactions
        _assetContract.approve(_swapperAddress, _borrowAmount);
        uint256 _initialCollateralBalance = _collateralContract.balanceOf(address(this));
        ISwapper(_swapperAddress).swapExactTokensForTokens(
            _borrowAmount,
            _amountCollateralOutMin,
            _path,
            address(this),
            block.timestamp
        );
        uint256 _finalCollateralBalance = _collateralContract.balanceOf(address(this));

        // VIOLATES CHECKS-EFFECTS-INTERACTION pattern, make sure function is NONREENTRANT
        // Effects: bookkeeping & write to state
        uint256 _amountCollateralOut = _finalCollateralBalance - _initialCollateralBalance;
        if (_amountCollateralOut < _amountCollateralOutMin) {
            revert SlippageTooHigh(_amountCollateralOutMin, _amountCollateralOut);
        }

        // address(this) as _sender means no transfer occurs as pair already received the collateral during swap
        _addCollateral(address(this), _amountCollateralOut, msg.sender);

        _totalCollateralBalance = _initialCollateralAmount + _amountCollateralOut;
        emit LeveragedPosition(
            msg.sender,
            _swapperAddress,
            _borrowAmount,
            _borrowShares,
            _initialCollateralAmount,
            _amountCollateralOut
        );
    }

    /// @notice The ```RepayAssetWithCollateral``` event is emitted whenever ```repayAssetWithCollateral()``` is invoked
    /// @param _borrower The borrower account for which the repayment is taking place
    /// @param _swapperAddress The address of the whitelisted swapper to use for token swaps
    /// @param _collateralToSwap The amount of Collateral Token to swap and use for repayment
    /// @param _amountAssetOut The amount of Asset Token which was repaid
    /// @param _sharesRepaid The number of Borrow Shares which were repaid
    event RepayAssetWithCollateral(
        address indexed _borrower,
        address _swapperAddress,
        uint256 _collateralToSwap,
        uint256 _amountAssetOut,
        uint256 _sharesRepaid
    );

    /// @notice The ```repayAssetWithCollateral``` function allows a borrower to repay their debt using existing collateral in contract
    /// @param _swapperAddress The address of the whitelisted swapper to use for token swaps
    /// @param _collateralToSwap The amount of Collateral Tokens to swap for Asset Tokens
    /// @param _amountAssetOutMin The minimum amount of Asset Tokens to receive during the swap
    /// @param _path An array containing the addresses of ERC20 tokens to swap.  Adheres to UniV2 style path params.
    /// @return _amountAssetOut The amount of Asset Tokens received for the Collateral Tokens, the amount the borrowers account was credited
    function repayAssetWithCollateral(
        address _swapperAddress,
        uint256 _collateralToSwap,
        uint256 _amountAssetOutMin,
        address[] calldata _path
    ) external nonReentrant approvedBorrower isSolvent(msg.sender) returns (uint256 _amountAssetOut) {
        _addInterest();
        _updateExchangeRate();

        IERC20 _assetContract = assetContract;
        IERC20 _collateralContract = collateralContract;

        if (!swappers[_swapperAddress]) {
            revert BadSwapper();
        }
        if (_path[0] != address(_collateralContract)) {
            revert InvalidPath(address(_collateralContract), _path[0]);
        }
        if (_path[_path.length - 1] != address(_assetContract)) {
            revert InvalidPath(address(_assetContract), _path[_path.length - 1]);
        }

        // Effects: bookkeeping & write to state
        // Debit users collateral balance in preparation for swap, setting _recipient to address(this) means no transfer occurs
        _removeCollateral(_collateralToSwap, address(this), msg.sender);

        // Interactions
        _collateralContract.approve(_swapperAddress, _collateralToSwap);
        uint256 _initialAssetBalance = _assetContract.balanceOf(address(this));
        ISwapper(_swapperAddress).swapExactTokensForTokens(
            _collateralToSwap,
            _amountAssetOutMin,
            _path,
            address(this),
            block.timestamp
        );
        uint256 _finalAssetBalance = _assetContract.balanceOf(address(this));

        // VIOLATES CHECKS-EFFECTS-INTERACTION pattern, make sure function is NONREENTRANT
        // Effects: bookkeeping
        _amountAssetOut = _finalAssetBalance - _initialAssetBalance;
        if (_amountAssetOut < _amountAssetOutMin) {
            revert SlippageTooHigh(_amountAssetOutMin, _amountAssetOut);
        }

        VaultAccount memory _totalBorrow = totalBorrow;
        uint256 _sharesToRepay = _totalBorrow.toShares(_amountAssetOut, false);

        // Effects: write to state
        // setting _payer to address(this) means no actual transfer will occur.  Contract already has funds
        _repayAsset(_totalBorrow, _amountAssetOut, _sharesToRepay, address(this), msg.sender);

        emit RepayAssetWithCollateral(msg.sender, _swapperAddress, _collateralToSwap, _amountAssetOut, _sharesToRepay);
    }
}

// SPDX-License-Identifier: ISC
pragma solidity ^0.8.15;

struct VaultAccount {
    uint128 amount; // Total amount, analogous to market cap
    uint128 shares; // Total shares, analogous to shares outstanding
}

/// @title VaultAccount Library
/// @author Drake Evans (Frax Finance) github.com/drakeevans, modified from work by @Boring_Crypto github.com/boring_crypto
/// @notice Provides a library for use with the VaultAccount struct, provides convenient math implementations
/// @dev Uses uint128 to save on storage
library VaultAccountingLibrary {
    /// @notice Calculates the shares value in relationship to `amount` and `total`
    /// @dev Given an amount, return the appropriate number of shares
    function toShares(
        VaultAccount memory total,
        uint256 amount,
        bool roundUp
    ) internal pure returns (uint256 shares) {
        if (total.amount == 0) {
            shares = amount;
        } else {
            shares = (amount * total.shares) / total.amount;
            if (roundUp && (shares * total.amount) / total.shares < amount) {
                shares = shares + 1;
            }
        }
    }

    /// @notice Calculates the amount value in relationship to `shares` and `total`
    /// @dev Given a number of shares, returns the appropriate amount
    function toAmount(
        VaultAccount memory total,
        uint256 shares,
        bool roundUp
    ) internal pure returns (uint256 amount) {
        if (total.shares == 0) {
            amount = shares;
        } else {
            amount = (shares * total.amount) / total.shares;
            if (roundUp && (amount * total.shares) / total.amount < shares) {
                amount = amount + 1;
            }
        }
    }
}

// SPDX-License-Identifier: ISC
pragma solidity >=0.8.15;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

interface IERC4626 is IERC20, IERC20Metadata {
    event Deposit(address indexed caller, address indexed owner, uint256 assets, uint256 shares);
    event Withdraw(
        address indexed caller,
        address indexed receiver,
        address indexed owner,
        uint256 assets,
        uint256 shares
    );

    function asset() external view returns (address);

    function convertToAssets(uint256 shares) external view returns (uint256);

    function convertToShares(uint256 assets) external view returns (uint256);

    function maxDeposit(address) external view returns (uint256);

    function maxMint(address) external view returns (uint256);

    function maxRedeem(address owner) external view returns (uint256);

    function maxWithdraw(address owner) external view returns (uint256);

    function previewDeposit(uint256 assets) external view returns (uint256);

    function previewMint(uint256 shares) external view returns (uint256);

    function previewRedeem(uint256 shares) external view returns (uint256);

    function previewWithdraw(uint256 assets) external view returns (uint256);

    function totalAssets() external view returns (uint256);

    function mint(uint256 shares, address receiver) external returns (uint256 assets);

    function deposit(uint256 assets, address receiver) external returns (uint256 shares);

    function redeem(
        uint256 shares,
        address receiver,
        address owner
    ) external returns (uint256 assets);

    function withdraw(
        uint256 assets,
        address receiver,
        address owner
    ) external returns (uint256 shares);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.15;

interface ISwapper {
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}
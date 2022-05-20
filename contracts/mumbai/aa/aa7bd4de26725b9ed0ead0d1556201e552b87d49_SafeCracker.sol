/**
 *Submitted for verification at polygonscan.com on 2022-05-19
*/

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;


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

// File: @openzeppelin/contracts/utils/math/SafeMath.sol


// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// File: safec.sol


// SAFECRACKER SIMPLU

pragma solidity ^0.8.0;



contract SafeCracker is Ownable{
    
    uint randNonce = 0;
    uint pinLength = 1; // -----------------
    // uint256 public time = block.timestamp;
    address creator;
    struct VaultModel {
        string name;
        uint256 amount;
        uint256 pinLength;
        bool active;
        uint256 tries;
        uint deposits;
    }

    event Generate(string me, string vault);


    VaultModel public Vault;
    uint256 public tax;
    address[] OwnersCounter;
    mapping(address => uint256) public OwnersBalance;
    
    
    constructor(){
        creator = msg.sender;
        Vault = VaultModel("Vault-v1", 0, pinLength, true, 0, 0);
    }

    
    function depositInVault() payable public isHuman{
        require(
            msg.sender != address(0) && msg.sender != address(this),
            "err 1"
        );
        require(msg.value > 0, "You need to send some Ether");
        
        uint256 value = msg.value;
        uint256 currentTax = SafeMath.div(value,100);
        Vault.amount = Vault.amount + value - currentTax;
        tax = currentTax + tax;
        if(OwnersBalance[msg.sender] > 0){
            OwnersBalance[msg.sender] = OwnersBalance[msg.sender] + value - currentTax;
        }else{
            OwnersCounter.push(msg.sender);
            OwnersBalance[msg.sender] = value - currentTax;
        }
        Vault.deposits = Vault.deposits + value - currentTax;
    }
    
    function crackTheVault(string memory pin) payable public isHuman returns(bool){
        require(msg.sender != address(0) && msg.sender != address(this),"err 1");
        require(stringLength(pin) == pinLength, "Wrong Pin length.");
        //todo: de calculat pretul tx
        require(msg.value > 0, "You need to send some Ether");
        require(Vault.pinLength == stringLength(pin), "Wrong ping lenght");
        uint256 value = msg.value;
        uint256 currentTax = SafeMath.div(value,100);
        Vault.amount = Vault.amount + msg.value - currentTax;
        tax = currentTax + tax;
        Vault.tries = Vault.tries + 1;
        bool successCrack = checkPIN(pin);
        if(successCrack){
                // A castigat !!!!!!!
                address payable sender = payable(msg.sender);
                sender.transfer(Vault.amount);
                //reset !?
                Vault.tries = 0;
                Vault.amount = 0;
                Vault.deposits = 0;
                for (uint i=0; i < OwnersCounter.length; i++) {
                    delete OwnersBalance[OwnersCounter[i]];
                }
                delete OwnersCounter;
                return true;
        }else{
                // A pierdut !!!!!!
                distribute();
                return false;
        }
        
    }

    function calculateOwnerBalance() public view isHuman returns(uint _balance){
        require(msg.sender != address(0) && msg.sender != address(this),"err 1");
        require(OwnersBalance[msg.sender] > 0, "Owner not exists");
        // uint percentage = calcul(OwnersBalance[msg.sender], Vault.deposits, 2);
        // uint balance = SafeMath.mul(Vault.amount, percentage) / 100; 
        return OwnersBalance[msg.sender];
    }

    function distribute() internal {
        for (uint i=0; i < OwnersCounter.length; i++) {
            uint percentage = calcOwnerPercentage(OwnersCounter[i]);
            uint balance = SafeMath.mul(Vault.amount, percentage) / 100;
            OwnersBalance[OwnersCounter[i]] = balance;
        }
    }

    function calcOwnerPercentage(address who) public view returns(uint _percentage){
        uint percentage = calcul(OwnersBalance[who], Vault.deposits, 2);
        return percentage;
    }

    function withdrawOwnerBalance() public isHuman returns(bool){
        require(msg.sender != address(0) && msg.sender != address(this),"err 1");
        require(OwnersBalance[msg.sender] > 0, "Owner not exists");
        uint balance = OwnersBalance[msg.sender];
        Vault.deposits = Vault.deposits - balance;
        Vault.amount = Vault.amount - balance;
        address payable sender = payable(msg.sender);
        for (uint i=0; i < OwnersCounter.length; i++) {
            if(OwnersBalance[OwnersCounter[i]] == OwnersBalance[msg.sender]){
                delete OwnersBalance[msg.sender];
                delete OwnersCounter[i];
            }
        }
        distribute();
        sender.transfer(balance);
        return true;
    }

    function ownersCount() public view returns(uint256) {
        return OwnersCounter.length;
    }

    function withdrawTax() public {
        require(
            msg.sender != address(0) && msg.sender != address(this),
            "err 1"
        );
        require(msg.sender == creator, "Access denied !");
        address payable sender = payable(msg.sender);
        sender.transfer(tax);
        tax = 0;
     }
    
    function checkPIN(string memory pin) public returns(bool){
        //conditions
        if(stringLength(pin) == 1){
            uint n1 = randMod(10);
            string memory n1s = uint2str(n1);
            // emit Generate(pin, n1s);
            string memory nToString = string(abi.encodePacked(n1s));
            if (keccak256(bytes(nToString)) == keccak256(bytes(pin))) {
                return true;
            }else{
                return false;
            }
        }
       if(stringLength(pin) == 4){
            uint n1 = randMod(10);
            uint n2 = randMod(10);
            uint n3 = randMod(10);
            uint n4 = randMod(10);
            
            string memory n1s = uint2str(n1);
            string memory n2s = uint2str(n2);
            string memory n3s = uint2str(n3);
            string memory n4s = uint2str(n4);
            
            string memory nToString = string(abi.encodePacked(n1s,n2s,n3s,n4s));
            if (keccak256(bytes(nToString)) == keccak256(bytes(pin))) {
                return true;
            }else{
                return false;
            }
        }
        return false;
    }

    function randMod(uint256 m) internal returns (uint256) {
        randNonce++;
        uint256 seed =
            uint256(
                keccak256(
                    abi.encodePacked(
                        block.timestamp +
                            block.difficulty +
                            ((
                                uint256(
                                    keccak256(abi.encodePacked(block.coinbase))
                                )
                            ) / (block.timestamp)) +
                            block.gaslimit +
                            ((
                                uint256(keccak256(abi.encodePacked(msg.sender)))
                            ) / (block.timestamp)) +
                            block.number,
                        randNonce
                    )
                )
            );

        return (seed - ((seed / 1000) * 1000)) % m;
    }
    
    function contractBalance() public view returns (uint256) {
        return address(this).balance;
    }

        //** Require
    modifier isHuman() {
        address _addr = msg.sender;
        uint256 _codeLength;
        
        assembly {_codeLength := extcodesize(_addr)}
        require(_codeLength == 0, "sorry, humans only");
        _;
    }

    function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len;
        while (_i != 0) {
            k = k-1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }
    
    function stringLength(string memory s) internal pure returns (uint256) {
      return bytes(s).length;
    }
    
    // https://ethereum.stackexchange.com/questions/15090/cant-do-any-integer-division
    function calcul(uint a, uint b, uint precision) internal pure returns ( uint) {
         return a*(10**precision)/b;
     }
}
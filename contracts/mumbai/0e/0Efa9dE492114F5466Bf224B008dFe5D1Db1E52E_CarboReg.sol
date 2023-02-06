/**
 *Submitted for verification at polygonscan.com on 2023-02-05
*/

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


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


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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

// File: contracts/carboReg.sol

//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.9;



interface IToken is IERC20{
    function mint(address account, uint amount) external;

    function burn(address account, uint amount) external;

}

contract CarboReg is Ownable {

    address tokenContract;

    struct GenApplication{
        uint id;
        uint fees;
        string status;
        uint tokens;
        address comp_addr;
        address verifier_addr;
        uint subDate;
        uint accDate;
        uint procDate;
        string reportIpfs;
    }   

    struct Company{
        string name;
        string location;
        uint contact;
        uint reg_no;
        // uint carbon_emission;
        // uint creditsHeld;
        // uint offset;
        // bool isSafe;
        bool isVerified;
        uint dateOfReg; 
        bool exists;
        uint[] pastApplications;
        // uint lastVerificationDate;
    }

    struct Verifier{
        string name;
        string location;
        uint contact;
        uint reg_no;
        uint license_no;
        uint[] pastApplications;
        uint[] currentApplications;
        bool exists;
    }

    mapping (address => Company) private allCompanies;
    mapping (address => Verifier) private allVerifiers;
    mapping(uint => GenApplication) private allApplications;
    uint[] public openApplications;


    uint public totalRegistered = 0;
    uint public verifiercount=0;
    uint public  customercount = 0;
    uint public applications = 0;

    fallback() external payable {}

    receive() external payable {}

    modifier onlyRegedCompany(address wallet){
        require(allCompanies[wallet].exists, "Company not registered!");
        _;
    }

    modifier onlyRegedVerifier(address wallet){
        require(allVerifiers[wallet].exists, "Verifier not registered");
        _;
    }

    function setTokenContract(address _tokenContract) public payable onlyOwner{
        tokenContract = _tokenContract;
    }

    function RegisterCompany(string memory _name, string memory _location, uint _contact, uint _reg_no) public payable {
        require(!allCompanies[msg.sender].exists, "The Company's already registered!");
        totalRegistered++;
        customercount++;
        uint[] memory initHistory;
        allCompanies[msg.sender] = Company(_name, _location, _contact, _reg_no, false, block.timestamp, true, initHistory);
    
    }

    function RegisterVerifier(address verifier_addr, string memory _name, string memory _location, uint _contact, uint _reg_no, uint _license_no) public payable onlyOwner{
        require(!allVerifiers[verifier_addr].exists, "The Verifier's already registered!");
        totalRegistered++;
        verifiercount++;
        uint[] memory initHistory;
        allVerifiers[verifier_addr] = Verifier(_name, _location, _contact, _reg_no, _license_no, initHistory, initHistory, true);
    }

    function Verify(address comp_wallet, uint _type) public payable onlyOwner{
        if(_type==0)
            allCompanies[comp_wallet].isVerified = true;
        else
            allCompanies[comp_wallet].isVerified = false;
        // allCompanies[comp_wallet].creditsHeld = (allCompanies[comp_wallet].carbon_emission-emission_limit > 0)? allCompanies[comp_wallet].carbon_emission-emission_limit : 0;
        // allCompanies[comp_wallet].isSafe = (allCompanies[comp_wallet].carbon_emission-emission_limit > 0);
    }

    function getCompDetails(address _compWallet) public view returns (Company memory) {
        return allCompanies[_compWallet];
    }

    function getVeriferDetails(address _verifierWallet) public view returns (Verifier memory) {
        return allVerifiers[_verifierWallet];
    }

    function ApplyForGen(uint _fees) public payable onlyRegedCompany(msg.sender){
        GenApplication memory curr_app = GenApplication(applications, _fees, "open", 0, msg.sender, address(0), block.timestamp, 0, 0, "");
        allApplications[applications] = curr_app;
        openApplications.push(applications);
        allCompanies[msg.sender].pastApplications.push(applications);
        applications++;

    }

    function AcceptApplication(uint id) public payable onlyRegedVerifier(msg.sender){
        uint idx;
        bool found =false;
        for (uint8 i = 0; i < openApplications.length; i++){
            if(openApplications[i] == id){
                idx=i;
                found =true;
                break;
            }
        }
        require(found, "Application either does not exist or is closed");
        openApplications[idx] = openApplications[openApplications.length - 1];
        openApplications.pop();

        allApplications[id].status = "pending";
        allApplications[id].verifier_addr = msg.sender;
        allApplications[id].accDate = block.timestamp;

        allVerifiers[msg.sender].currentApplications.push(id);
    }

    function ProcessApplication(uint id, bool accept, uint _tokens, string memory _report) public payable onlyRegedVerifier(msg.sender){
        uint idx;
        bool found =false;
        for (uint8 i = 0; i < allVerifiers[msg.sender].currentApplications.length; i++){
            if(allVerifiers[msg.sender].currentApplications[i] == id){
                idx=i;
                found =true;
                break;
            }
        }
        require(found, "Application does not exist!");
        allVerifiers[msg.sender].currentApplications[idx] = allVerifiers[msg.sender].currentApplications[allVerifiers[msg.sender].currentApplications.length - 1];
        allVerifiers[msg.sender].currentApplications.pop();
        if(accept){
            allApplications[id].tokens=_tokens;
            allApplications[id].reportIpfs= _report;
            allApplications[id].status="accepted";

            // mint and send tokens
            IToken(tokenContract).mint(allApplications[id].comp_addr, _tokens); 
        }else{
            allApplications[id].status="rejected";
        }
        allVerifiers[msg.sender].pastApplications.push(id);
        
    }

    function closeApplication(uint id) public payable onlyRegedCompany(msg.sender){
        uint idx1;
        bool found1 =false;
        uint idx;
        bool found =false;
        for (uint8 i = 0; i < openApplications.length; i++){
            if(openApplications[i] == id){
                idx=i;
                found =true;
                break;
            }
        }
        
        for (uint8 i = 0; i < allCompanies[msg.sender].pastApplications.length; i++){
            if(allCompanies[msg.sender].pastApplications[i] == id){
                idx1=i;
                found1 =true;
                break;
            }
        }
        require(found && found1, "Application does not exist!");
        openApplications[idx] = openApplications[openApplications.length - 1];
        openApplications.pop();

        allApplications[id].status="closed";
    }


}
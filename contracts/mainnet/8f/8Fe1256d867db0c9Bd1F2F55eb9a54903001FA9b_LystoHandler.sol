/**
 *Submitted for verification at polygonscan.com on 2023-06-21
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)




// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)



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


contract LystoHandler is Ownable {

    struct MintAndTransferInfo {
        address tokenContractAddress; //address of contract to mint token from
        address receiverAddr; //address to transfer token after minting
        uint256 tokenId;
    }

    struct TokenInfo {
        address tokenContractAddress; //address of contract to fetch information
        uint256[] tokenIds; 
    }

    mapping (address => bool) public approvedAddresses; //list of approved addresses
    address public manager; 

    event managerChanged(address indexed managerAddr);
    event approvedAddressAdded(address indexed addr);
    event approvedAddressRemoved(address indexed addr);

    constructor (address _managerAddress) {
        setManager(_managerAddress);
    }

    //function to add a approved address
    function setManager(address addr) public onlyOwner {
        require(addr != address(0), "Can not be zero!");
        manager = addr;
        emit managerChanged(addr);
    }

    //function to add a approved address
    function addApprovedAddress(address addr) external isManagerOrOwner {
        approvedAddresses[addr] = true;
        emit approvedAddressAdded(addr);
    }

    // function to remove address from list of approved address
    function removeApprovedAddress(address addr) external isManagerOrOwner {
        approvedAddresses[addr] = false;
        emit approvedAddressRemoved(addr);
    } 

    // function to mint and transfer token from another contract
    function mintAndTransfer(MintAndTransferInfo memory info) public isApprovedAddress {
        PoPPInterface poPP = PoPPInterface(info.tokenContractAddress);
        poPP.mint(info.receiverAddr, info.tokenId);
    }

    // function to bulk mint and transfer token from another contract
    function bulkMintAndTransfer(MintAndTransferInfo[] memory info) public isApprovedAddress {
        for(uint i = 0; i < info.length; i++) {
            mintAndTransfer(info[i]);
        }
    }

    // function to get tokenIds owned by user across multiple contracts
    function getOwnedTokenDetails(address[] memory addrs, address user) external view returns(TokenInfo[] memory) {
        TokenInfo[] memory tokensInfo = new TokenInfo[](addrs.length);
        for(uint i = 0; i < addrs.length; i++) {
            TokenInfo memory tokenInfo = getTokenIds(addrs[i], user);
            tokensInfo[i] = tokenInfo;
        }
        return tokensInfo;
    }

    // function to get tokenIds owned by user in given contract
    function getTokenIds(address contractAddr, address user) public  view returns (TokenInfo memory) {
        PoPPInterface poPP = PoPPInterface(contractAddr);
        uint256 totalTokens = poPP.balanceOf(user);
        uint256[] memory tokenIds = new uint256[](totalTokens);
        if (totalTokens > 0) {
            for(uint i = 0; i < totalTokens; i++) {
                uint256 tokenId = poPP.tokenOfOwnerByIndex(user, i);
                tokenIds[i]= tokenId;
            }
        } 
        TokenInfo memory tokenInfo = TokenInfo(contractAddr, tokenIds);
        return tokenInfo;
        
    }

    // function to get total count of tokens owned by user across multiple contracts
    function getTokenCount(address[] memory addrs, address user) external view returns(uint256) {
        uint256 totalTokens = 0;
        for(uint i = 0; i < addrs.length; i++) {
            PoPPInterface poPP = PoPPInterface(addrs[i]);
            uint256 tokenCount = poPP.balanceOf(user);
            totalTokens = totalTokens + tokenCount;
        }
        return totalTokens;
    }

    

    //pause minting in a particular contract
    function pauseMint(address contractAddr) public isManagerOrOwner {
        PoPPInterface poPP = PoPPInterface(contractAddr);
        poPP.pauseMinting();
    }

    //Unpause minting in a particular contract
    function unpauseMint(address contractAddr) public isManagerOrOwner {
        PoPPInterface poPP = PoPPInterface(contractAddr);
        poPP.unPauseMinting();
    }

    //set base uri in a particular contract
    function setBaseURI(address contractAddr, string memory nftBaseURI) public isManagerOrOwner {
        PoPPInterface poPP = PoPPInterface(contractAddr);
        poPP.setBaseURI(nftBaseURI);
    }

    //set this contract as handlerAddress in a particular contract
    function setHandler(address[] memory contractAddr, address handlerAddress) public isManagerOrOwner {
        for(uint i = 0; i < contractAddr.length; i++) {
            PoPPInterface poPP = PoPPInterface(contractAddr[i]);
            poPP.setHandlerAddress(handlerAddress);
        }
    }

    function deployPoPP(string memory name, string memory symbol,
        string memory baseURI, string memory contractType, address ownerAddress, address contractAddr) public isManagerOrOwner {
            PoPPFactoryInterface poPPFactory = PoPPFactoryInterface(contractAddr);
            poPPFactory.createPoPP(name, symbol, baseURI, contractType, ownerAddress);
    }


    // check if address is allowed to mint from this contract
    modifier isApprovedAddress() {
        require(msg.sender==owner() || approvedAddresses[msg.sender]==true, "Unauthorised");
        _;
    } 

    // check if address is allowed to mint from this contract
    modifier isManagerOrOwner() {
        require(msg.sender==owner() || msg.sender==manager, "Unauthorised");
        _;
    }     

}

interface PoPPInterface {
  function mint(address receiver, uint256 tokenId) external;
  function balanceOf(address user) external view returns (uint256);
  function tokenOfOwnerByIndex(address user, uint256 index) external view returns (uint256);
  function pauseMinting() external;
  function unPauseMinting() external;
  function setBaseURI(string memory nftBaseURI) external;
  function setHandlerAddress(address addr) external;
}

interface PoPPFactoryInterface {
    function createPoPP(string memory name, string memory symbol,
        string memory baseURI, string memory contractType, address ownerAddress) external;
}
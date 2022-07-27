// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.12;

import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title VenlyERC1155Interface
 * @dev Venly Smart Contract interface
 */
contract VenlyERC1155Interface {
  function noTokensForType(uint256) public returns (uint256) {}
  function mintNonFungible(uint256 typeId, uint256 id, address account) public {}
}


/**
 * @title MintingEvent
 */
contract MintingEvent is Ownable {

    address public venlyContract;
    uint256 public mintingPrice = 0.06 ether;
    uint256 public maxMintPerAccount = 1;

    uint256[] public tokenTypeIds;
    uint256 public lastMintedTokenIdx = 0;

    bool public paused = true;

    mapping(address => uint256) private minterBalance;

    VenlyERC1155Interface venlySc;

    event MintedToken(uint256, uint256, address);

    function setBaseContractAddress(address addr) external onlyOwner {
        venlyContract = addr;
        venlySc = VenlyERC1155Interface(addr);
    }

    function setTokenTypeIds(uint256[] memory ids) external onlyOwner {
        require(ids.length > 0, "Range must have a least one item");
        tokenTypeIds = ids;
        if (lastMintedTokenIdx != 0) {
            lastMintedTokenIdx = 0;
        }
    }

    function setPaused(bool state) external onlyOwner {
        paused = state;
    }

    // optimize gaz cost with unchecked mechanism
    function unsafe_inc(uint x) private pure returns (uint) {
        unchecked { return x + 1; }
    }

    function mintToken() external payable {
        require(paused == false, "Minting event is paused");
        require(msg.value >= mintingPrice, "Ether received must be > to minting price");
        require(minterBalance[msg.sender] < maxMintPerAccount, "Only 1 token can be minted per account");
        // optimize gaz cost with memory variables for read/write
        uint _lastMintedTokenIdx = lastMintedTokenIdx;
        uint[] memory _tokenTypeIds = tokenTypeIds;
        require(_lastMintedTokenIdx < _tokenTypeIds.length, "No more available tokens to mint");
        for (uint i = _lastMintedTokenIdx; i < _tokenTypeIds.length - 1; i = unsafe_inc(i)) {
            // check tokenTypeIds[i] is minted
            // if not stop and set lastMintedTokenIdx to i
            // should we compare to maxSupply of tokenType ? if yes multiple users
            // could have the same token
            if (venlySc.noTokensForType(_tokenTypeIds[i]) == 0) {
                _lastMintedTokenIdx = i;
                break;
            }
            i++;
        }
        venlySc.mintNonFungible(_tokenTypeIds[_lastMintedTokenIdx], _tokenTypeIds[_lastMintedTokenIdx] + 100, msg.sender);
        minterBalance[msg.sender] = unsafe_inc(minterBalance[msg.sender]);
        emit MintedToken(_tokenTypeIds[_lastMintedTokenIdx], _tokenTypeIds[_lastMintedTokenIdx] + 100, msg.sender);
        lastMintedTokenIdx = unsafe_inc(_lastMintedTokenIdx);
    }

    function setMintingPrice(uint256 price) external onlyOwner {
        require(price > 0, "Minting price must be > 0");
        mintingPrice = price;
    }

    function setMaxMintPerAccount(uint256 amount) external onlyOwner {
        require(amount > 0, "Max mint per account must be > 0");
        maxMintPerAccount = amount;
    }

    // Function to withdraw all Ether from this contract.
    function withdraw() external onlyOwner {
        // get the amount of Ether stored in this contract
        uint amount = address(this).balance;

        // send all Ether to owner
        // Owner can receive Ether since the address of owner is payable
        (bool success, ) = payable(owner()).call{value: amount}("");
        require(success, "Failed to send Ether");
    }

    // Function to transfer Ether from this contract to address from input
    function transfer(address payable _to, uint _amount) external onlyOwner {
        // Note that "to" is declared as payable
        (bool success, ) = _to.call{value: _amount}("");
        require(success, "Failed to send Ether");
    }

    function balance() external view returns (uint256) {
        return address(this).balance;
    }
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
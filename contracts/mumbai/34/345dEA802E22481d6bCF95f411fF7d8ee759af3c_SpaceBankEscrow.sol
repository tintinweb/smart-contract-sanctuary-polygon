//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract SpaceBankEscrow is Ownable{

    IERC20 public GSM;
    IERC20 public xGSM;

    uint[3] public FEES = [5 ether,5 ether,5 ether];

    struct tradeItem{
        address contractAddress;
        uint tokenId;
    }

    struct tradeInfo{
        tradeItem[] self;
        tradeItem[] opp;
        address selfAddress;
        address oppAddress;
    }

    struct tradePos{
        uint selfPos;
        uint oppPos;
    }

    struct feeInfo{
        uint8 feeChoice;
        uint feeAmount;
    }

    mapping(uint=>tradeInfo) trades;
    mapping(uint=>tradePos) tradePosition;
    mapping(uint=>feeInfo) tradeFees; 
    mapping(address=>uint[]) sentTrades;
    mapping(address=>uint[]) receivedTrades;

    uint[3] public feeGenerated;

    uint tradeID;

    constructor(address _xgsm) {
        GSM = IERC20(_xgsm);
    }

    function startTrade(tradeItem[] memory selfTrade,tradeItem[] memory oppTrade,address opp,uint8 feeChoice) external payable{
        payFees(feeChoice,(selfTrade.length+oppTrade.length));
        tradeID++;

        tradeFees[tradeID] = feeInfo(feeChoice,FEES[feeChoice]*(selfTrade.length+oppTrade.length));

        for(uint i=0;i<selfTrade.length;i++){
            IERC721(selfTrade[i].contractAddress).transferFrom(msg.sender, address(this), selfTrade[i].tokenId);
            trades[tradeID].self.push(selfTrade[i]);
        }

        for(uint i=0;i<oppTrade.length;i++){
            trades[tradeID].opp.push(oppTrade[i]);
        }

        trades[tradeID].selfAddress = msg.sender;
        trades[tradeID].oppAddress = opp;

        tradePosition[tradeID] = tradePos(sentTrades[msg.sender].length,receivedTrades[opp].length);

        sentTrades[msg.sender].push(tradeID);
        receivedTrades[opp].push(tradeID);
    }

    function acceptTrade(uint tradeId,uint8 feeChoice) external payable{
        require(trades[tradeId].oppAddress == msg.sender,"SpaceBank: Invalid sender");


        tradeItem[] storage item = trades[tradeId].opp;
        tradeItem[] storage receiveItem = trades[tradeId].self;

        payFees(feeChoice,item.length+receiveItem.length);
        feeGenerated[feeChoice] += FEES[feeChoice] * (item.length+receiveItem.length);

        address opp = trades[tradeId].oppAddress;

        for(uint i=0;i<item.length;i++){
            IERC721(item[i].contractAddress).transferFrom(msg.sender,opp,item[i].tokenId);
        }

        for(uint i=0;i<item.length;i++){
            IERC721(receiveItem[i].contractAddress).transferFrom(address(this), msg.sender, receiveItem[i].tokenId);
        }

        acceptFees(tradeId);
        popTrade(tradeId);
        delete trades[tradeId];
    }

    function declineTrade(uint tradeId) external {
        require(trades[tradeId].oppAddress == msg.sender || trades[tradeId].selfAddress==msg.sender,"SpaceBank: Invalid sender");

        tradeItem[] storage item = trades[tradeId].self;
        address self = trades[tradeId].selfAddress;

        for(uint i=0;i<item.length;i++){
            IERC721(item[i].contractAddress).transferFrom(address(this),self, item[i].tokenId);
        }

        refundFees(tradeId);
        popTrade(tradeId);
        delete trades[tradeId];
    }

    function acceptFees(uint tradeId) private{
        feeInfo storage info = tradeFees[tradeId];
        feeGenerated[info.feeChoice] += info.feeAmount;
        delete tradeFees[tradeId];
    }

    function refundFees(uint tradeId) private{
        feeInfo storage info = tradeFees[tradeId];
        if(info.feeChoice == 0){
            (bool sent, ) = payable(trades[tradeId].selfAddress).call{value:info.feeAmount}("");
            require(sent, "SpaceBank: Failed to send refund");
        }
        else if(info.feeChoice == 1){
            xGSM.transfer(trades[tradeId].selfAddress,info.feeAmount);
        }
        else{
            GSM.transfer(trades[tradeId].selfAddress,info.feeAmount);
        }
        delete tradeFees[tradeId];
    }

    function payFees(uint8 feeChoice,uint amount) private {
        if(feeChoice == 0){
            require(msg.value == FEES[0]*amount,"SpaceBank: Underpaid");
        }
        else if(feeChoice == 1){
            require(msg.value == 0,"SpaceBank: Multipaid");
            xGSM.transferFrom(msg.sender,address(this),FEES[1]*amount);
        }
        else if(feeChoice == 2){
            require(msg.value == 0,"SpaceBank: Multipaid");
            GSM.transferFrom(msg.sender,address(this),FEES[2]*amount);
        }
        else{
            revert("SpaceBank: Invalid choice");
        }
    }

    function popTrade(uint tradeId) private{
        tradeInfo storage info = trades[tradeId];
        _popSent(info.selfAddress, tradePosition[tradeId].selfPos);
        _popReceived(info.oppAddress, tradePosition[tradeId].oppPos);
        delete tradePosition[tradeId];
    }

    function _popSent(address _user,uint _index) private{
        uint lastTrade = sentTrades[_user][sentTrades[_user].length-1];
        sentTrades[_user][_index] = lastTrade;
        tradePosition[lastTrade].selfPos = _index;
        sentTrades[_user].pop();
    }

    function _popReceived(address _user,uint _index) private{
        uint lastTrade = receivedTrades[_user][receivedTrades[_user].length-1];
        receivedTrades[_user][_index] = lastTrade;
        tradePosition[lastTrade].oppPos = _index;
        receivedTrades[_user].pop();
    }

    function getTradeInfo(uint id) external view returns(tradeInfo memory){
        return trades[id];
    }

    function getSentTrades(address _user) external view returns(uint[] memory){
        return sentTrades[_user];
    } 

    function getReceivedTrades(address _user) external view returns(uint[] memory){
        return receivedTrades[_user];
    }

    function collectFees() external onlyOwner{
        uint[3] memory fees = feeGenerated;
        delete feeGenerated;
        (bool sent, ) = payable(owner()).call{value:fees[0]}("");
        require(sent,"SpaceBank: Collection failed");
        xGSM.transfer(owner(), fees[1]);
        GSM.transfer(owner(), fees[2]);
    }

    function setFees(uint[3] memory fees) external onlyOwner{
        FEES = fees;
    }

    function setGSM(address _gsm) external onlyOwner{
        GSM = IERC20(_gsm);
    }

    function setxGSM(address _xgsm) external onlyOwner{
        xGSM = IERC20(_xgsm);
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20.sol";

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
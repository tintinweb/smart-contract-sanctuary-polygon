// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/utils/ERC1155Holder.sol)

pragma solidity ^0.8.0;

import "./ERC1155Receiver.sol";

/**
 * Simple implementation of `ERC1155Receiver` that will allow a contract to hold ERC1155 tokens.
 *
 * IMPORTANT: When inheriting this contract, you must include a way to use the received tokens, otherwise they will be
 * stuck.
 *
 * @dev _Available since v3.1._
 */
contract ERC1155Holder is ERC1155Receiver {
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/utils/ERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../IERC1155Receiver.sol";
import "../../../utils/introspection/ERC165.sol";

/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155Receiver is ERC165, IERC1155Receiver {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId || super.supportsInterface(interfaceId);
    }
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

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC7254 standard as defined in the EIP.
 */
interface IERC7254 {

    struct UserInformation {
        uint256 inReward;
        uint256 outReward;
        uint256 withdraw;
    }

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
     * @dev Emitted when the add reward  of a `contributor` is set by
     * a call to {approve}.
     */
    event UpdateReward(address indexed contributor, uint256 value);

    /**
     * @dev Emitted when `value` tokens reward to
     * `caller`.
     *
     * Note that `value` may be zero.
     */
    event GetReward(address indexed owner, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Returns user information by `account`.
     */
    function informationOf(address account) external view  returns (UserInformation memory);

    /**
     * @dev Returns token reward.
     */
    function tokenReward() external view returns (address);


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

    /**
     * @dev Add `amount` tokens .
     *
     * Returns a rewardPerShare.
     *
     * Emits a {UpdateReward} event.
     */
    function updateReward(uint256 amount) external returns(uint256);

    /**
     * @dev Returns the amount of reward by `account`.
     */
    function viewReward(address account) external returns (uint256);

    /**
     * @dev Moves reward to caller.
     *
     * Returns a amount value of reward.
     *
     * Emits a {GetReward} event.
     */
    function getReward() external returns(uint256);
}

interface IReferral {
    function getSponsor(address user) external view returns(address);
    function getRef(address user) external view returns(address[] memory);
    function getFee() external view returns(uint);
    function getCharity() external view returns(address);
    function getReceiver(address user) external view returns(address);
}

interface IRouter {

    function getReferral() external view returns (address);

    function launchpadAddLiquidity(
        address token, 
        address nft, 
        uint256 id,
        uint amountTokenDesired,
        uint amountNFTDesired,
        uint amountTokenMin,
        address to, 
        uint deadline
    ) external returns(address);
}

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}

library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferFromNFT(address nft, address from, address to, uint256 id, uint value, bytes memory dataNFT) internal {
        // bytes4(keccak256(bytes('safeTransferFrom(address,address,uint256,uint256,bytes)')))
        (bool success, bytes memory data) = nft.call(abi.encodeWithSelector(0xf242432a, from, to, id, value, dataNFT));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_NFT_FAILED');
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
    
}

// Receive token
// add liquidity and transfer reward 
// unlock liquidity 
pragma solidity ^0.8.9;
import { ERC1155Holder } from "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "../interface/IReferral.sol";
import "../interface/IWETH.sol";
// import "../interface/ICreator.sol";
import "../ERC7254/IERC7254.sol";
import "../library/TransferHelper.sol";
import "../interface/IRouter.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
interface ICreator {
    function burn(uint _id, uint _amount) external;
}
contract LaunchPad is ERC1155Holder {
    struct launchpad_data {
        address creator;
        uint id;
        uint initial;
        uint totalSell;
        uint percentLock;
        uint price;
        uint priceListing;
        address tokenPayment;
        uint startTime;
        uint endTime;
        uint durationLock;
        uint maxbuy;
        bool refundType;
        bool whiteList;
        uint percentReferral;
    }

    launchpad_data public LaunchPadInfo;
    uint public totalSoldout;
    uint public totalTokenReceive;
    uint public totalRewardReferral;
    address referral;
    address WETH;
    address dml;
    address NFT;
    address router;
    uint maxNFTLock;
    bool isListed = false;
    mapping(address => bool) public admin;
    mapping(address => bool) public isWhitelisted;
    mapping(address => uint) public balanceOf;
    constructor(launchpad_data memory launchpad_information, uint _maxNFTLock, address _nft, address _referral, address _weth, address _router) {
        // refund type: true: burn, false: refund
        // whitelist: true: enable, false: disable
        //  1% -> 10000
        LaunchPadInfo = launchpad_information;
        referral = _referral;
        WETH = _weth;
        NFT = _nft;
        maxNFTLock = _maxNFTLock;
        router = _router;
    }

    receive() external payable {
        assert(msg.sender == WETH); // only accept ETH via fallback from the WETH contract
    }

    modifier onlyCreator(){
         require(msg.sender == LaunchPadInfo.creator, "Only Creator");
        _;
    }  

    modifier onlyAdmin(){
        require(admin[msg.sender] || msg.sender == LaunchPadInfo.creator, "Only Admin or Creator");
        _;
    }

    modifier verifyAmount(uint _amount){
        require(totalSoldout + _amount <= LaunchPadInfo.totalSell, "Exceed amount");
        _;
    }
    modifier verifyWhiteList(){
        if(LaunchPadInfo.whiteList){
            require(isWhitelisted[msg.sender], "No whitelist");
        }
        _;
    }

    modifier verifyTimeClaimDml(){
        uint timeClaim = LaunchPadInfo.endTime + LaunchPadInfo.durationLock;
        require(timeClaim <= block.timestamp, "Waiting time");
        _;
    }

    modifier verifyTimeClaim(){
        require(block.timestamp > LaunchPadInfo.endTime, "Waiting end");
        _;
    }

    modifier verifyTimeBuy(){
        require(block.timestamp > LaunchPadInfo.startTime && block.timestamp <= LaunchPadInfo.endTime, "Sold out");
        _;
    }

    event Admin(
        address admin,
        bool status,
        uint blockTime
    );

    event WhiteList(
        address user,
        bool status,
        uint blockTime
    );

    event Buy(
        address user,
        uint amount,
        uint totalSold,
        uint blockTime
    );

    event Claim(
        address user,
        uint amount,
        uint blockTime
    );

    event Listing(
        address dml,
        uint totalTokenAddLiquidity,
        uint totalNFTAddLiquidity,
        uint totalBurn,
        uint totalNFTReceive,
        uint totalTokenReceive,
        uint blockTime
    );

     function addAdmin(address[] memory _admin, bool[] memory _status) external onlyCreator() {
        for(uint i =0; i < _admin.length; i++){
            admin[_admin[i]] = _status[i];
            emit Admin(_admin[i], _status[i], block.timestamp);
        }
    }

    function addWhieList(address[] memory _address, bool[] memory _status) external onlyAdmin(){
        require(LaunchPadInfo.whiteList, "WhiteList is disable");
        require(_address.length == _status.length, "Input Wrong");
        for(uint i = 0; i < _address.length; i++){
            isWhitelisted[_address[i]] = _status[i];
            emit WhiteList(_address[i], _status[i], block.timestamp);
        }
    }

    function buy(uint _amount) external verifyWhiteList() verifyTimeBuy() verifyAmount(_amount){
        uint amount = LaunchPadInfo.price * _amount;
        TransferHelper.safeTransferFrom(LaunchPadInfo.tokenPayment, msg.sender, address(this), amount);
        balanceOf[msg.sender] += _amount;
        totalSoldout += _amount;
        totalTokenReceive += amount;
        _tranferToReferral(amount);
        emit Buy(msg.sender, _amount, totalSoldout, block.timestamp);
    }

    function buyETH(uint _amount) external payable verifyWhiteList() verifyTimeBuy() verifyAmount(_amount){
        require(LaunchPadInfo.tokenPayment == WETH);
        uint amount = LaunchPadInfo.price * _amount;
        require(amount >= msg.value, "Amount is low");
        IWETH(WETH).deposit{value: msg.value}();
        if (msg.value > amount) TransferHelper.safeTransferETH(msg.sender, msg.value - amount);
        balanceOf[msg.sender] += _amount;
        totalSoldout += _amount;
        totalTokenReceive += amount;
        _tranferToReferral(amount);
        emit Buy(msg.sender, _amount, totalSoldout, block.timestamp);
    }

    function claim() external verifyTimeClaim(){
        require(isListed, "Wait Listing");
        require(balanceOf[msg.sender] > 0, "Balance = 0");
        uint amount = balanceOf[msg.sender];
        balanceOf[msg.sender] = 0;
        TransferHelper.safeTransferFromNFT(NFT, address(this), msg.sender, LaunchPadInfo.id, amount, bytes(''));
        emit Claim(msg.sender, amount, block.timestamp);
    }

    function showList() public view returns(uint){
        uint refund = LaunchPadInfo.totalSell - totalSoldout;
        uint totalBurn = LaunchPadInfo.refundType ? refund : 0;
        uint totalRefund = refund - totalBurn;
        uint totalNFTReceive = LaunchPadInfo.initial + totalRefund;
        uint tokenAddLiquidity = totalTokenReceive * LaunchPadInfo.percentLock / 1000000;
        uint NFTAddLiquidity = tokenAddLiquidity / LaunchPadInfo.priceListing;
        uint totalNFTAddLiquidity = maxNFTLock > NFTAddLiquidity ? NFTAddLiquidity : maxNFTLock;
        uint remaining = maxNFTLock - totalNFTAddLiquidity;
        return (totalBurn + remaining);
    }
    function listing() external verifyTimeClaim(){
        // transfer money and initial token to creator
        uint refund = LaunchPadInfo.totalSell - totalSoldout;
        uint totalBurn = LaunchPadInfo.refundType ? refund : 0;
        uint totalRefund = refund - totalBurn;
        uint totalNFTReceive = LaunchPadInfo.initial + totalRefund;
        uint tokenAddLiquidity = totalTokenReceive * LaunchPadInfo.percentLock / 1000000;
        uint NFTAddLiquidity = tokenAddLiquidity / LaunchPadInfo.priceListing;
        uint totalNFTAddLiquidity = maxNFTLock > NFTAddLiquidity ? NFTAddLiquidity : maxNFTLock;
        uint remaining = maxNFTLock - totalNFTAddLiquidity;
        TransferHelper.safeTransfer(LaunchPadInfo.tokenPayment, router, tokenAddLiquidity);
        TransferHelper.safeTransferFromNFT(NFT, address(this) , router, LaunchPadInfo.id, totalNFTAddLiquidity, bytes(''));
        dml = IRouter(router).launchpadAddLiquidity(LaunchPadInfo.tokenPayment, NFT, LaunchPadInfo.id, tokenAddLiquidity, totalNFTAddLiquidity, 0, address(this), block.timestamp + 20*60);
        // if((totalBurn + remaining) > 0){
        //     ICreator(NFT).burn(LaunchPadInfo.id, (totalBurn + remaining));
        // }
        if(totalNFTReceive > 0){
            TransferHelper.safeTransferFromNFT(NFT, address(this), LaunchPadInfo.creator, LaunchPadInfo.id, totalNFTReceive, bytes(''));
        }
        if((totalTokenReceive - tokenAddLiquidity - totalRewardReferral) > 0){
            TransferHelper.safeTransfer(LaunchPadInfo.tokenPayment, LaunchPadInfo.creator, (totalTokenReceive - tokenAddLiquidity - totalRewardReferral));
        }
        isListed = true;
        emit Listing(dml, tokenAddLiquidity, totalNFTAddLiquidity, (totalBurn + remaining), totalNFTReceive, (totalTokenReceive - tokenAddLiquidity), block.timestamp);
    }

    function claimDml() external onlyCreator() verifyTimeClaimDml(){
        uint256 balance = IERC7254(dml).balanceOf(address(this));
        TransferHelper.safeTransfer(dml, msg.sender, balance);
        uint256 reward = IERC7254(dml).getReward();
        address tokenReward = IERC7254(dml).tokenReward();
        TransferHelper.safeTransfer(tokenReward, msg.sender, reward);
    }

    function claimReward() external onlyCreator(){
        uint256 reward = IERC7254(dml).getReward();
        address tokenReward = IERC7254(dml).tokenReward();
        TransferHelper.safeTransfer(tokenReward, msg.sender, reward);
    }

    function _tranferToReferral(uint _amount) internal {
        uint amountFee = _amount * LaunchPadInfo.percentReferral / 1000000;
        totalRewardReferral += amountFee;
        if(amountFee > 0)  TransferHelper.safeTransfer(LaunchPadInfo.tokenPayment, IReferral(referral).getReceiver(msg.sender), amountFee);
    }

}
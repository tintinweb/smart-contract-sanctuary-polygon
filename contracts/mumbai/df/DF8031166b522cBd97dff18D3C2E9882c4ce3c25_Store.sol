// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "./Ownable.sol";
import "./Address.sol";
import "./IERC721.sol";
import "./IERC20.sol";
import "./SafeMath.sol";
import "./ReentrancyGuard.sol";
import "./TransferHelper.sol";

contract Store is Ownable, ReentrancyGuard {
    using SafeMath for uint256;

    address public recipient;

    struct UnitPrice {
        address token;
        uint amount;
    }
    mapping(address => UnitPrice) public price;
    mapping(uint => UnitPrice) public plan;

    constructor(address _recipient) {
        _updateRecipient(_recipient);
    }

    // 接收ETH NFT
    receive() external payable {}

    fallback() external payable {}

    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual returns (bytes4) {
        return this.onERC721Received.selector;
    }

    event MintRoute(
        uint uid,
        address nft,
        address recipient,
        uint256 tokenId,
        uint256 amount,
        uint96 fee,
        string tokenUri,
        address token,
        uint price
    );

    event PlanPay(uint uid, uint pid, address token, uint amount);

    struct MintParams {
        address recipient;
        uint256 tokenId;
        uint256 amount;
        uint96 fee;
        string tokenUri;
    }

    function mint(
        uint uid,
        address nft,
        MintParams[] memory params
    ) public payable nonReentrant {
        receiveToken(nft, params.length);
        for (uint i = 0; i < params.length; i++) {
            IERC721(nft).mintAlone(
                params[i].recipient,
                params[i].tokenId,
                params[i].amount,
                params[i].fee,
                params[i].tokenUri
            );
            emit MintRoute(
                uid,
                nft,
                params[i].recipient,
                params[i].tokenId,
                params[i].amount,
                params[i].fee,
                params[i].tokenUri,
                price[nft].token,
                price[nft].amount
            );
        }
    }

    function planPay(uint uid, uint pid) public payable {
        _tokenSend(plan[pid].token, plan[pid].amount);
        emit PlanPay(uid, pid, plan[pid].token, plan[pid].amount);
    }

    function receiveToken(address nft, uint count) internal {
        address token = price[nft].token;
        uint amount = price[nft].amount.mul(count);
        _tokenSend(token, amount);
    }

    function _tokenSend(address token, uint amount) private {
        if (token == address(0)) {
            require(msg.value == amount, "Store::input eth is not accurate");
            Address.sendValue(payable(recipient), msg.value);
        } else {
            TransferHelper.safeTransferFrom(
                token,
                msg.sender,
                recipient,
                amount
            );
        }
    }

    function updatePrice(
        address nft,
        address token,
        uint amount
    ) public onlyOwner {
        price[nft] = UnitPrice({token: token, amount: amount});
    }

    function updatePlan(uint id, address token, uint amount) public onlyOwner {
        plan[id] = UnitPrice({token: token, amount: amount});
    }

    function updateRecipient(address _recipient) public onlyOwner {
        _updateRecipient(_recipient);
    }

    function _updateRecipient(address _recipient) private {
        recipient = _recipient;
    }
}
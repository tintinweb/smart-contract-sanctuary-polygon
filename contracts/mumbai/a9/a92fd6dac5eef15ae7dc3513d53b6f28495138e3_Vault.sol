// SPDX-License-Identifier: None
pragma solidity 0.8.19;

import "./IERC20.sol";
import "./IERC165.sol";
import "./IERC721.sol";
import "./IERC1155.sol";

contract Vault {

    address payable owner;

    constructor(address _owner) {
        owner = payable(_owner);
    }

    receive() external payable {}
    fallback() external payable {}

    modifier onlyOwner {
        require(msg.sender == owner, "Denied.");
        _;
    }

    // Withdraw ERC-20 Tokens
    function withdraw(uint _amount) onlyOwner external {
        require(_amount < address(this).balance, "Insufficient Funds");
        transfer(owner, _amount);
    }

    function withdrawERC20(IERC20 _token, uint _amount) onlyOwner external {
        require(_amount <= _token.balanceOf(address(this)), "Insuffucient Funds.");
        _token.transfer(owner, _amount);
    }

    function isOwner(address _user) external view returns (bool) {
        if(_user == owner) {
            return true;
        }
        return false;
    }
    
    // https://github.com/lexDAO/Kali/blob/main/contracts/libraries/SafeTransferLib.sol
    error TransferFailed();
    function transfer(address _to, uint _amount) private {
        bool callStatus;
        assembly {
            callStatus := call(gas(), _to, _amount, 0, 0, 0, 0)
        }
        if(!callStatus) revert TransferFailed();
    }

    // Allows ERC-721 Tokens to be owned by this contract
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public pure returns (bytes4) {
        return this.onERC721Received.selector;
    }

    // Withdraw ERC-721 Tokens
    function withdrawERC721(IERC721 _token, uint256 _tokenID) onlyOwner external {
        _token.safeTransferFrom(address(this), owner, _tokenID);
    }

    // Allows ERC-1155 Tokens to be owned by this contract
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) external pure returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) external pure returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }

    // Withdraw ERC-1155 Tokens
    function withdrawERC1155(IERC1155 _token, uint256 _tokenID, uint256 _value, bytes calldata _data) onlyOwner external {
        _token.safeTransferFrom(address(this), owner, _tokenID, _value, _data);
    }

    // Batch withdraw ERC-1155 Tokens
    function withdrawBatchERC1155(IERC1155 _token, uint256[] calldata _ids, uint256[] calldata _values, bytes calldata _data) onlyOwner external {
        _token.safeBatchTransferFrom(address(this), owner, _ids, _values, _data);
    }
}
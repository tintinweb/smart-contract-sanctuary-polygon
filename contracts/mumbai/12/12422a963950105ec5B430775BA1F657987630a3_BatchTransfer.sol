/**
 *Submitted for verification at polygonscan.com on 2023-02-15
*/

pragma solidity ^0.8.0;


abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}





            

pragma solidity >=0.8.4;


library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "TransferHelper: APPROVE_FAILED");
    }

    function safeTransfer(address token, address to, uint value) internal {
        
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "TransferHelper: TRANSFER_FAILED");
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "TransferHelper: TRANSFER_FROM_FAILED");
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, "TransferHelper: ETH_TRANSFER_FAILED");
    }
}




            



pragma solidity ^0.8.0;


interface IERC20 {
    
    event Transfer(address indexed from, address indexed to, uint256 value);

    
    event Approval(address indexed owner, address indexed spender, uint256 value);

    
    function totalSupply() external view returns (uint256);

    
    function balanceOf(address account) external view returns (uint256);

    
    function transfer(address to, uint256 amount) external returns (bool);

    
    function allowance(address owner, address spender) external view returns (uint256);

    
    function approve(address spender, uint256 amount) external returns (bool);

    
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}





            



pragma solidity ^0.8.0;




abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    
    constructor() {
        _transferOwnership(_msgSender());
    }

    
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    
    function owner() public view virtual returns (address) {
        return _owner;
    }

    
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}






pragma solidity >=0.8.4;





contract BatchTransfer is Ownable {
    event TokenBatchTransfer(address indexed operator, address indexed token, address[] to, uint values);
    mapping(address => bool) transferRecord;
    mapping(address => bool) transferEthRecord;

    constructor() {
    }

    receive() external payable {

    }

     function batchTransferAll(address _token, address[] memory _to, uint _value, uint _ethValue) external onlyOwner {
       batchTransfer(_token, _to, _value);
       batchTransferETH(_to, _ethValue);
    }


    function batchTransfer(address _token, address[] memory _to, uint _value) public onlyOwner {
        uint balance = IERC20(_token).balanceOf(address(this));
        require(balance >= _value * _to.length, "insufficient balance");
        for (uint i = 0; i < _to.length; i++) {
            if (!transferRecord[_to[i]]) {
                TransferHelper.safeTransfer(_token, _to[i], _value);
                transferRecord[_to[i]] = true;
            }
        }
        emit TokenBatchTransfer(msg.sender, _token, _to, _value);
    }

    function batchTransferETH(address[] memory _to, uint _value) public payable onlyOwner {
        require(address(this).balance >= _value * _to.length, "insufficient balance");
        uint i;
        for (i = 0; i < _to.length; i++) {           
             if (!transferEthRecord[_to[i]]) {
                TransferHelper.safeTransferETH(_to[i], _value);
                transferEthRecord[_to[i]] = true;
            }
        }
        emit TokenBatchTransfer(msg.sender, address(0), _to, _value);
    }

    function withdrawTokens(address _token) external onlyOwner {
        uint balance = IERC20(_token).balanceOf(address(this));
        require(balance > 0, "BatchTransfer: No balance");

        TransferHelper.safeTransfer(_token, msg.sender, balance);
    }

    function withdrawETH() external onlyOwner {
        uint balance = address(this).balance;
        require(balance > 0, "BatchTransfer: No balance");

        (bool success,) = msg.sender.call{value: balance}("");
        require(success, "BatchTransfer: Withdrawal failed");
    }

}
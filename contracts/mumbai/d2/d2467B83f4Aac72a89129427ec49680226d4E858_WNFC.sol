/**
 *Submitted for verification at polygonscan.com on 2023-05-02
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

library Address {
    
    function isContract(address account) internal view returns (bool) {
        

        return account.code.length > 0;
    }

    
    function sendValue(address payable recipient, uint256 amount) internal {
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
    }

    
    function functionCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return functionCall(target, data, "Address: low-level call failed");
    }

    
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return
            functionCallWithValue(
                target,
                data,
                value,
                "Address: low-level call with value failed"
            );
    }

    
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(
            address(this).balance >= value,
            "Address: insufficient balance for call"
        );
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(
            data
        );
        return verifyCallResult(success, returndata, errorMessage);
    }

    
    function functionStaticCall(address target, bytes memory data)
        internal
        view
        returns (bytes memory)
    {
        return
            functionStaticCall(
                target,
                data,
                "Address: low-level static call failed"
            );
    }

    
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    
    function functionDelegateCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return
            functionDelegateCall(
                target,
                data,
                "Address: low-level delegate call failed"
            );
    }

    
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            
            if (returndata.length > 0) {
                

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

interface IBEP20 {
    
    function totalSupply() external view returns (uint256);

    
    function balanceOf(address account) external view returns (uint256);

    
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    
    function approve(address spender, uint256 amount) external returns (bool);

    
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    
    event Transfer(address indexed from, address indexed to, uint256 value);

   
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}


library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IBEP20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transfer.selector, to, value)
        );
    }

    function safeTransferFrom(
        IBEP20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transferFrom.selector, from, to, value)
        );
    }

    
    function safeApprove(
        IBEP20 token,
        address spender,
        uint256 value
    ) internal {
        
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.approve.selector, spender, value)
        );
    }

    function safeIncreaseAllowance(
        IBEP20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
    }

    function safeDecreaseAllowance(
        IBEP20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(
                oldAllowance >= value,
                "SafeERC20: decreased allowance below zero"
            );
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(
                token,
                abi.encodeWithSelector(
                    token.approve.selector,
                    spender,
                    newAllowance
                )
            );
        }
    }

    
    function _callOptionalReturn(IBEP20 token, bytes memory data) private {
        

        bytes memory returndata = address(token).functionCall(
            data,
            "SafeERC20: low-level call failed"
        );
        if (returndata.length > 0) {
            // Return data is optional
            require(
                abi.decode(returndata, (bool)),
                "SafeERC20: ERC20 operation did not succeed"
            );
        }
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}


abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    
    constructor() {
        _transferOwnership(_msgSender());
    }

    
    function owner() public view virtual returns (address) {
        return _owner;
    }

    
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _transferOwnership(newOwner);
    }

    
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}


abstract contract Pausable is Context {
    
    event Paused(address account);

    
    event Unpaused(address account);

    bool private _paused;

    
    constructor() {
        _paused = false;
    }

    
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

abstract contract ReentrancyGuard {
    
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    
    modifier nonReentrant() {
        
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

       
        _status = _ENTERED;

        _;

        _status = _NOT_ENTERED;
    }
}

contract WNFC is Pausable, Ownable, ReentrancyGuard {
    
    using SafeERC20 for IBEP20;
    IBEP20 public Token;
    uint256 public walletFee1 = 100; //1%
    uint256 public walletFee2 = 190; //1%
    uint256 public walletFee3 = 10; //1%

    address public TotalPercentWallet;
    address public wallet1;
    address public wallet2;
    address public wallet3;

    constructor(
        address _tokenaddress
    ) {
        Token = IBEP20(_tokenaddress);
        TotalPercentWallet = 0x940049B8f3521E7524bE9d95d8A2669Ec3C37Cca;
        wallet1 = 0x940049B8f3521E7524bE9d95d8A2669Ec3C37Cca;
        wallet2 = 0x940049B8f3521E7524bE9d95d8A2669Ec3C37Cca;
        wallet3 = 0x940049B8f3521E7524bE9d95d8A2669Ec3C37Cca;

    }

    event Buy(address indexed user, uint256 value, uint256 amount);
    event ChangeAdminWallet(address Wallet);
    event changeTotalPercent(address);

    function changeAdminWallet(address first_wallet, address second_wallet, address third_wallet)
        external
        onlyOwner
    {
        require(first_wallet != address(0), "Invalid Address");
        require(second_wallet != address(0), "Invalid Address");
        require(third_wallet != address(0), "Invalid Address");
        wallet1 = first_wallet;
        wallet2 = second_wallet;
        wallet3 = third_wallet;
        emit ChangeAdminWallet(wallet1);
    }

    function changeTotalPercentWallet(address _TotalPercentWallet)
        external
        onlyOwner
    {
        require(_TotalPercentWallet != address(0), "Invalid Address");
        TotalPercentWallet = _TotalPercentWallet;
        emit changeTotalPercent(_TotalPercentWallet);
    }


    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    

    function pay(
        uint256 amount,
        uint256 _flag
    ) external payable whenNotPaused nonReentrant {
        require(_flag == 1 || _flag == 2, "WNFC : Invalid flag");
        if (_flag == 1) {
            require(msg.value == 0 && amount > 0, "WNFC: Invalid Amount");

            uint256 FadminPrice = (amount * walletFee1) / 10000;
            uint256 SadminPrice = (amount * walletFee2) / 10000;
            uint256 DadminPrice = (amount * walletFee3) / 10000;
            uint256 TotaladminPrice = FadminPrice + SadminPrice;
            Token.safeTransferFrom(msg.sender, address(this), amount);
            Token.safeTransfer(TotalPercentWallet, amount - TotaladminPrice);
            Token.safeTransfer(wallet1, FadminPrice);
            Token.safeTransfer(wallet2, SadminPrice);
            Token.safeTransfer(wallet3, DadminPrice);
        } else {
            require(msg.value > 0 && amount == 0, "WNFC: Invalid Amount");

            uint256 FadminPrice = (msg.value * walletFee1) / 10000;
            uint256 SadminPrice = (msg.value * walletFee2) / 10000;
            uint256 DadminPrice = (msg.value * walletFee3) / 10000;
            uint256 TotaladminPrice = FadminPrice + SadminPrice + DadminPrice;
            require(
                payable(TotalPercentWallet).send(msg.value - TotaladminPrice),
                "WNFC : Transaction Failed"
            );
            require(
                payable(wallet1).send(FadminPrice),
                "WNFC : Transaction Failed1 "
            );
            require(
                payable(wallet2).send(SadminPrice),
                "WNFC : Transaction Failed2 "
            );

            require(
                payable(wallet3).send(DadminPrice),
                "WNFC : Transaction Failed3 "
            );
        }

        emit Buy(TotalPercentWallet, msg.value, amount);
    }

    function updateTokenaddress(address _token) external onlyOwner {
        require(_token != address(0), "Token must be 0");
        Token = IBEP20(_token);
    }

    function updateAdminFee(uint256 F_adminFee, uint256 S_adminFee, uint256 D_adminFee)
        external
        onlyOwner
    {
        walletFee1 = F_adminFee;
        walletFee2 = S_adminFee;
        walletFee3 = D_adminFee;
    }

    function emergency(
        address token,
        address to,
        uint256 amount
    ) external onlyOwner {
        if (token == address(0x0)) {
            payable(to).transfer(amount);
        } else {
            IBEP20(token).transfer(to, amount);
        }
    }
}
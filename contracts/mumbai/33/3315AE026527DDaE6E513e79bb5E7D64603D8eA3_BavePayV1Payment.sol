// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./interfaces/IBavePayV1Payment.sol";
import "./interfaces/IBavePayV1Factory.sol";
import "./interfaces/IERC20.sol";
import "./libraries/SafeMath.sol";

contract BavePayV1Payment is IBavePayV1Payment {
    using SafeMath for uint256;

    bytes4 private constant TRANSFER_SELECTOR =
        bytes4(keccak256(bytes("transfer(address,uint256)")));
    bytes4 private constant TRANSFERFROM_SELECTOR =
        bytes4(keccak256(bytes("transferFrom(address,address,uint256)")));

    mapping(address => uint256) public balanceOf;
    mapping(address => bool) public allowedToken;

    address[] public allTokens;

    address public clientAcct;
    address public clientOper;
    address public factory;

    uint256 public rate;
    uint256 public paymentId;

    constructor(
        address _clientAcct,
        address _clientOper,
        address[] memory _tokens,
        uint256 _rate,
        uint256 _paymentId
    ) {
        clientAcct = _clientAcct;
        clientOper = _clientOper;
        allTokens = _tokens;
        rate = _rate;
        paymentId = _paymentId;
        factory = msg.sender;
        for (uint256 i = 0; i < _tokens.length; i++) {
            allowedToken[_tokens[i]] = true;
        }
    }

    modifier ensure(uint256 deadline) {
        require(deadline >= block.timestamp);
        _;
    }
    modifier onlyBaveOper() {
        require(msg.sender == baveOper());
        _;
    }
    modifier jointCtrl() {
        require(msg.sender == baveOper() || msg.sender == clientOper);
        _;
    }

    function allTokensLength() external view returns (uint256) {
        return allTokens.length;
    }

    function commissionInfo(uint256 balance)
        public
        view
        returns (uint256 commissionAmt)
    {
        commissionAmt = (balance * rate) / 10000;
        return (commissionAmt);
    }

    function baveAcct() public view returns (address) {
        return IBavePayV1Factory(factory).baveAcct();
    }

    function baveOper() public view returns (address) {
        return IBavePayV1Factory(factory).baveOper();
    }

    function paymentNative(uint256 deadline) external payable ensure(deadline) {
        require(msg.value > 0);
        uint256 commission = commissionInfo(msg.value);
        uint256 balance = msg.value.sub(commission);
        balanceOf[address(0)] = balanceOf[address(0)].add(balance);
        _ledger(address(0), msg.sender, address(this), msg.value);
        _ledger(address(0), address(this), baveAcct(), commission);
        payable(baveAcct()).transfer(commission);
    }

    function paymentToken(
        address tokenAddr,
        uint256 amount,
        uint256 deadline
    ) external ensure(deadline) {
        require(amount > 0);
        require(allowedToken[tokenAddr]);
        uint256 commission = commissionInfo(amount);
        uint256 balance = amount.sub(commission);
        balanceOf[tokenAddr] = balanceOf[tokenAddr].add(balance);
        _ledger(tokenAddr, msg.sender, address(this), amount);
        _ledger(tokenAddr, address(this), baveAcct(), commission);
        _safeTransferFrom(tokenAddr, msg.sender, address(this), amount);
        _safeTransfer(tokenAddr, baveAcct(), commission);
    }

    function withdraw(address tokenAddr) public jointCtrl {
        require(tokenAddr == address(0) || allowedToken[tokenAddr]);
        uint256 balance = balanceOf[tokenAddr];
        if (balance > 0) {
            balanceOf[tokenAddr] = balanceOf[tokenAddr].sub(balance);
            _ledger(tokenAddr, address(this), clientAcct, balance);
            if (tokenAddr == address(0)) {
                payable(clientAcct).transfer(balance);
            } else {
                _safeTransfer(tokenAddr, clientAcct, balance);
            }
        }
    }

    function withdrawAll() external jointCtrl {
        for (uint256 i = 0; i < allTokens.length; i++) {
            withdraw(allTokens[i]);
        }
        withdraw(address(0));
    }

    function baveWithdraw(address tokenAddr) external onlyBaveOper {
        if (tokenAddr == address(0)) {
            uint256 balance = (address(this).balance).sub(
                balanceOf[address(0)]
            );
            require(balance > 0);
            payable(baveAcct()).transfer(balance);
        } else {
            uint256 balance = (IERC20(tokenAddr).balanceOf(address(this))).sub(
                balanceOf[tokenAddr]
            );
            require(balance > 0);
            _safeTransfer(tokenAddr, baveAcct(), balance);
        }
    }

    function pushToken(address[] memory _tokens) external onlyBaveOper {
        _pushToken(_tokens);
    }

    function removeToken(uint256 index) external onlyBaveOper {
        _removeToken(index);
    }

    function _pushToken(address[] memory _tokens) private {
        for (uint256 i = 0; i < _tokens.length; i++) {
            address token = _tokens[i];
            require(!allowedToken[token]);
            allowedToken[token] = true;
            allTokens.push(token);
            _tokenChanged(token, true);
        }
    }

    function _removeToken(uint256 _index) private {
        address token = allTokens[_index];
        require(allowedToken[token]);
        allowedToken[token] = false;
        for (uint256 i = _index; i < allTokens.length - 1; i++) {
            allTokens[i] = allTokens[i + 1];
        }
        allTokens.pop();
        _tokenChanged(token, false);
    }

    function setClientAcct(address _clientAcct) external jointCtrl {
        require(_clientAcct != address(0));
        clientAcct = _clientAcct;
        _clientChanged(0, clientAcct, _clientAcct);
    }

    function setClientOper(address _clientOper) external jointCtrl {
        require(_clientOper != address(0));
        clientOper = _clientOper;
        _clientChanged(1, clientOper, _clientOper);
    }

    function _safeTransfer(
        address token,
        address to,
        uint256 value
    ) private {
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(TRANSFER_SELECTOR, to, value)
        );
        require(success && (data.length == 0 || abi.decode(data, (bool))));
    }

    function _safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) private {
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(TRANSFERFROM_SELECTOR, from, to, value)
        );
        require(success && (data.length == 0 || abi.decode(data, (bool))));
    }

    function _ledger(
        address token,
        address from,
        address to,
        uint256 amount
    ) private {
        IBavePayV1Factory(factory).ledger(paymentId, token, from, to, amount);
    }

    function _clientChanged(
        uint256 class,
        address oldClient,
        address newClient
    ) private {
        IBavePayV1Factory(factory).clientChanged(
            paymentId,
            class,
            oldClient,
            newClient
        );
    }

    function _tokenChanged(address token, bool boolean) private {
        IBavePayV1Factory(factory).tokenChanged(paymentId, token, boolean);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IBavePayV1Payment {
    function balanceOf(address) external view returns (uint256);
    function allowedToken(address) external view returns (bool);
    function allTokens(uint256) external view returns (address);
    function clientAcct() external view returns (address);
    function clientOper() external view returns (address);
    function factory() external view returns (address);
    function rate() external view returns (uint256);
    function paymentId() external view returns (uint256);

    function allTokensLength() external view returns (uint256);
    function commissionInfo(uint256) external view returns (uint256);
    function baveAcct() external view returns (address);
    function baveOper() external view returns (address);

    function paymentNative(uint256) external payable;
    function paymentToken(address, uint256, uint256) external;
    function withdraw(address) external;
    function withdrawAll() external;
    function baveWithdraw(address) external;
    function pushToken(address[] memory) external;
    function removeToken(uint256) external;
    function setClientAcct(address) external;
    function setClientOper(address) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IBavePayV1Factory {
    event PaymentCreated(uint256 paymentId, address indexed payment);
    event TokenChanged(uint256 paymentId, address indexed token, bool boolean);
    event BaveChanged(uint256 class, address indexed oldAddress, address indexed newAddress);
    event ClientChanged(uint256 paymentId, uint256 class, address indexed oldAddress, address indexed newAddress);
    event Ledger(
        uint256 paymentId,
        address indexed token,
        address indexed from,
        address indexed to,
        uint256 amount
    );

    function baveAcct() external view returns (address);
    function baveOper() external view returns (address);
    function allPayments(uint256) external view returns (address payment);

    function allPaymentsLength() external view returns (uint256);
    
    function createPayment(
        address clientAcct,
        address clientOper,
        address[] memory tokens,
        uint256 rate
    ) external returns (address payment);
    
    function setBaveAcct(address) external;
    function setBaveOper(address) external;

    function ledger(
        uint256 paymentId,
        address token,
        address from,
        address to,
        uint256 amount
    ) external;
    function clientChanged(
        uint256 paymentId,
        uint256 class,
        address oldClient,
        address newClient
    ) external;
    function tokenChanged(
        uint256 paymentId,
        address token,
        bool boolean
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

library SafeMath {
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, 'add-overflow');
    }

    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, 'sub-underflow');
    }
}
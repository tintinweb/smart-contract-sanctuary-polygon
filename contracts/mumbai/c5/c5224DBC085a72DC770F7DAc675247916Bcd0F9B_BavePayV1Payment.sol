// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./interfaces/IBavePayV1Payment.sol";
import "./interfaces/IBavePayV1Factory.sol";
import './interfaces/IERC20.sol';
import "./libraries/SafeMath.sol";

contract BavePayV1Payment is IBavePayV1Payment {
    using SafeMath for uint256;

    bytes4 private constant SELECTOR =
        bytes4(keccak256(bytes("transfer(address,uint256)")));

    mapping(address => uint256) public balanceOf;
    mapping(address => bool) public allowedToken;
    address[] public tokenArray;

    address public clientAcct;
    address public clientOper;
    address public factory;

    uint256 public rate;
    uint256 public paymentId;

    constructor(
        address _clientAcct,
        address _clientOper,
        address[] memory _tokenArray,
        uint256 _rate,
        uint256 _paymentId
    ) {
        clientAcct = _clientAcct;
        clientOper = _clientOper;
        tokenArray = _tokenArray;
        rate = _rate;
        paymentId = _paymentId;
        factory = msg.sender;
    }

    modifier ensure(uint256 deadline) {
        require(block.timestamp <= deadline);
        _;
    }
    modifier onlyBaveOper() {
        require(msg.sender == baveOper());
        _;
    }
    modifier onlyClientOper() {
        require(msg.sender == clientOper);
        _;
    }
    modifier jointCtrl() {
        require(msg.sender == baveOper() || msg.sender == clientOper);
        _;
    }

    function _safeTransfer(
        address token,
        address to,
        uint256 value
    ) private {
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(SELECTOR, to, value)
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
        IBavePayV1Factory(factory).clientChanged(paymentId, class, oldClient, newClient);
    }

    function paymentNative(uint256 deadline) external payable ensure(deadline) {
        require(msg.value > 0);
        balanceOf[address(0)] = balanceOf[address(0)].add(msg.value);
        _ledger(address(0), msg.sender, address(this), msg.value);
    }

    function paymentToken(
        address tokenAddr,
        uint256 amount,
        uint256 deadline
    ) external ensure(deadline) {
        require(allowedToken[tokenAddr]);
        require(amount > 0);
        balanceOf[tokenAddr] = balanceOf[tokenAddr].add(amount);
        _ledger(tokenAddr, msg.sender, address(this), amount);
        _safeTransfer(tokenAddr, address(this), amount);
    }

    function commissionInfo(uint256 balance)
        public
        view
        returns (uint256 commissionAmt)
    {
        commissionAmt = (balance * rate) / 10000;
        return (commissionAmt);
    }

    function pushToken(address[] memory _tokenArray) external onlyBaveOper {
        _pushToken(_tokenArray);
    }

    function removeToken(uint256 index) external onlyBaveOper {
        _removeToken(index);
    }

    function _pushToken(address[] memory _tokenArray) private {
        for (uint256 i = 0; i < _tokenArray.length; i++) {
            tokenArray.push(_tokenArray[i]);
            allowedToken[_tokenArray[i]] = true;
        }
    }

    function _removeToken(uint256 _index) private {
        allowedToken[tokenArray[_index]] = false;
        for (uint256 i = _index; i < tokenArray.length - 1; i++) {
            tokenArray[i] = tokenArray[i + 1];
        }
        tokenArray.pop();
    }

    function withdrawNative() public jointCtrl {
        uint256 balance = balanceOf[address(0)];
        if (balance > 0) {
            uint256 commission = commissionInfo(balance);
            uint256 clientBalance = balance.sub(commission);
            balanceOf[address(0)] = balanceOf[address(0)].sub(balance);
            _ledger(address(0), address(this), clientAcct, clientBalance);
            _ledger(address(0), address(this), baveAcct(), commission);
            payable(clientAcct).transfer(clientBalance);
            payable(baveAcct()).transfer(commission);
        }
    }

    function withdrawToken(address tokenAddr) public jointCtrl {
        uint256 balance = balanceOf[tokenAddr];
        if (balance > 0) {
            uint256 commission = commissionInfo(balance);
            uint256 clientBalance = balance.sub(commission);
            balanceOf[tokenAddr] = balanceOf[tokenAddr].sub(balance);
            _ledger(tokenAddr, address(this), clientAcct, clientBalance);
            _ledger(tokenAddr, address(this), baveAcct(), commission);
            _safeTransfer(tokenAddr, clientAcct, clientBalance);
            _safeTransfer(tokenAddr, baveAcct(), commission);
        }
    }

    function withdrawAll() external jointCtrl {
        for (uint256 i = 0; i < tokenArray.length; i++) {
            withdrawToken(tokenArray[i]);
        }
        withdrawNative();
    }

    function baveWithdraw(address tokenAddr) external onlyBaveOper {
        if (tokenAddr == address(0)) {
            uint256 balance = (address(this).balance).sub(
                balanceOf[address(0)]
            );
            if (balance > 0) {
                payable(baveAcct()).transfer(balance);
            }
        } else {
            uint256 balance = (IERC20(tokenAddr).balanceOf(address(this))).sub(
                balanceOf[tokenAddr]
            );
            if (balance > 0) {
                _safeTransfer(tokenAddr, baveAcct(), balance);
            }
        }
    }

    function baveAcct() public view returns (address) {
        return IBavePayV1Factory(factory).baveAcct();
    }

    function baveOper() public view returns (address) {
        return IBavePayV1Factory(factory).baveOper();
    }

    function setClientAcct(address _clientAcct) external jointCtrl {
        require(_clientAcct != address(0));
        _clientChanged(0, clientAcct, _clientAcct);
        clientAcct = _clientAcct;
    }

    function setClientOper(address _clientOper) external jointCtrl {
        require(_clientOper != address(0));
        _clientChanged(1, clientOper, _clientOper);
        clientOper = _clientOper;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IBavePayV1Payment {
    function balanceOf(address token) external view returns (uint256);
    function allowedToken(address token) external view returns (bool);
    function tokenArray(uint256) external view returns (address token);
    function clientAcct() external view returns (address);
    function clientOper() external view returns (address);
    function factory() external view returns (address);
    function rate() external view returns (uint256);

    function paymentNative(uint256) external payable;
    function paymentToken(address, uint256, uint256) external;
    function commissionInfo(uint256) external view returns (uint256);
    function pushToken(address[] memory) external;
    function removeToken(uint256) external;
    function withdrawNative() external;
    function withdrawToken(address) external;
    function withdrawAll() external;
    function baveWithdraw(address) external;

    function baveAcct() external view returns (address);
    function baveOper() external view returns (address);
    function setClientAcct(address) external;
    function setClientOper(address) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IBavePayV1Factory {
    event BaveChanged(uint256 class, address indexed oldBave, address indexed newBave);
    event ClientChanged(uint256 paymentId, uint256 class, address indexed oldClient, address indexed newClient);
    event PaymentCreated(uint256 paymentId, address indexed payment);
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
        address[] memory tokenArray,
        uint256 rate
    ) external returns (address payment);

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

    function setBaveAcct(address) external;
    function setBaveOper(address) external;
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
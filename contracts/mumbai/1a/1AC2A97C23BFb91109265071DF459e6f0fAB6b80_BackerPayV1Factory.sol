// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "./interfaces/IBackerPayV1Factory.sol";
import "./BackerPayV1Union.sol";

contract BackerPayV1Factory is IBackerPayV1Factory {
    uint256 public factoryId;
    address public factoryOper;
    address[] public allUnions;

    constructor(uint256 _factoryId, address _factoryOper) {
        factoryId = _factoryId;
        factoryOper = _factoryOper;
    }

    modifier onlyFactoryOper() {
        require(msg.sender == factoryOper);
        _;
    }

    function allUnionsLength() external view returns (uint256) {
        return allUnions.length;
    }

    function createUnion(
        address ownerAcct,
        address ownerOper,
        address ownerRoot
    ) external onlyFactoryOper returns (address union) {
        uint8 unionId = uint8(allUnions.length);
        union = address(
            new BackerPayV1Union(
                unionId,
                ownerAcct,
                ownerOper,
                ownerRoot
            )
        );
        allUnions.push(union);
        emit UnionCreated(unionId, union);
    }

    function setFactoryOper(address _factoryOper) external onlyFactoryOper {
        emit FactoryOperChanged(factoryOper, _factoryOper);
        factoryOper = _factoryOper;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

interface IBackerPayV1Factory {
    event FactoryOperChanged(address indexed oldAddress, address indexed newAddress);
    event UnionCreated(uint256 unionId, address indexed union);

    function factoryId() external view returns (uint256);
    function factoryOper() external view returns (address);
    function allUnions(uint256) external view returns (address);

    function allUnionsLength() external view returns (uint256);
    function createUnion(address, address, address)
        external
        returns (address);
    function setFactoryOper(address) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "./interfaces/IBackerPayV1Union.sol";
import "./interfaces/IERC20.sol";

contract BackerPayV1Union is IBackerPayV1Union {

    Union public union;
    mapping(uint32 => Payment) public payments;

    struct Union {
        uint32 allPaymentsLength;
        uint8 unionId;
        address ownerAcct;
        address ownerOper;
        address ownerRoot;
        address factory;
    }

    struct Payment {
        mapping(address => uint256) balanceOf;
        mapping(address => bool) allowedToken;
        address[] allTokens;
        address clientAcct;
        address clientOper;
        uint256 rate;
    }

    constructor(
        uint8 _unionId,
        address _ownerAcct,
        address _ownerOper,
        address _ownerRoot
    ) {
        Union storage u = union;
        u.unionId = _unionId;
        u.ownerAcct = _ownerAcct;
        u.ownerOper = _ownerOper;
        u.ownerRoot = _ownerRoot;
        u.factory = msg.sender;
    }

    modifier ensure(uint64 deadline) {
        require(deadline >= block.timestamp);
        _;
    }
    modifier onlyOwnerOper() {
        require(msg.sender == union.ownerOper);
        _;
    }
    modifier onlyOwnerRoot() {
        require(msg.sender == union.ownerRoot);
        _;
    }
    modifier jointOper(uint32 paymentId) {
        require(
            msg.sender == union.ownerOper ||
                msg.sender == payments[paymentId].clientOper
        );
        _;
    }
    modifier jointRoot(uint32 paymentId) {
        require(
            msg.sender == union.ownerRoot ||
                msg.sender == payments[paymentId].clientOper
        );
        _;
    }

    function getBalanceOf(uint32 paymentId, address tokenAddr)
        external
        view
        returns (uint256)
    {
        return payments[paymentId].balanceOf[tokenAddr];
    }

    function getAllowedToken(uint32 paymentId, address tokenAddr)
        external
        view
        returns (bool)
    {
        return payments[paymentId].allowedToken[tokenAddr];
    }

    function getAllTokensLength(uint32 paymentId)
        external
        view
        returns (uint256)
    {
        return payments[paymentId].allTokens.length;
    }

    function getAllTokens(uint32 paymentId, uint256 index)
        external
        view
        returns (address)
    {
        return payments[paymentId].allTokens[index];
    }

    function commissionInfo(uint32 paymentId, uint256 balance)
        public
        view
        returns (uint256 commissionAmt)
    {
        commissionAmt = (balance * payments[paymentId].rate) / 1000000;
        return (commissionAmt);
    }

    function createPayment(
        address _clientAcct,
        address _clientOper,
        address[] memory _tokens,
        uint256 _rate
    ) external onlyOwnerOper {
        uint32 _paymentId = union.allPaymentsLength++;
        Payment storage p = payments[_paymentId];
        p.allTokens = _tokens;
        p.clientAcct = _clientAcct;
        p.clientOper = _clientOper;
        p.rate = _rate;
        emit PaymentCreated(_paymentId);
        for (uint256 i = 0; i < _tokens.length; i++) {
            p.allowedToken[_tokens[i]] = true;
        }
    }

    function paymentNative(uint32 paymentId, uint64 deadline)
        external
        payable
        ensure(deadline)
    {
        require(msg.value > 0);
        uint256 commission = commissionInfo(paymentId, msg.value);
        uint256 balance = msg.value - commission;
        Payment storage p = payments[paymentId];
        p.balanceOf[address(0)] = p.balanceOf[address(0)] + balance;
        emit Ledger(
            paymentId,
            commission,
            msg.value,
            address(0),
            union.ownerAcct,
            msg.sender
        );
        payable(union.ownerAcct).transfer(commission);
    }

    function paymentToken(
        uint32 paymentId,
        uint64 deadline,
        uint256 amount,
        address tokenAddr
    ) external ensure(deadline) {
        require(amount > 0);
        Payment storage p = payments[paymentId];
        require(p.allowedToken[tokenAddr]);
        uint256 commission = commissionInfo(paymentId, amount);
        uint256 balance = amount - commission;
        p.balanceOf[tokenAddr] = p.balanceOf[tokenAddr] + balance;
        emit Ledger(paymentId, commission, amount, tokenAddr, union.ownerAcct, msg.sender);
        _safeTransferFrom(tokenAddr, msg.sender, address(this), amount);
        _safeTransfer(tokenAddr, union.ownerAcct, commission);
    }

    function withdraw(uint32 paymentId, address tokenAddr)
        public
        jointOper(paymentId)
    {
        Payment storage p = payments[paymentId];
        require(tokenAddr == address(0) || p.allowedToken[tokenAddr]);
        uint256 balance = p.balanceOf[tokenAddr];
        if (balance > 0) {
            p.balanceOf[tokenAddr] = p.balanceOf[tokenAddr] - balance;
            emit Withdraw(
                paymentId,
                tokenAddr,
                address(this),
                p.clientAcct,
                balance
            );
            if (tokenAddr == address(0)) {
                payable(p.clientAcct).transfer(balance);
            } else {
                _safeTransfer(tokenAddr, p.clientAcct, balance);
            }
        }
    }

    function withdrawAll(uint32 paymentId) external jointOper(paymentId) {
        Payment storage p = payments[paymentId];
        for (uint256 i = 0; i < p.allTokens.length; i++) {
            withdraw(paymentId, p.allTokens[i]);
        }
        withdraw(paymentId, address(0));
    }

    function ownerWithdraw(address tokenAddr) external onlyOwnerOper {
        uint256 subBalance;
        for (uint32 i = 0; i < union.allPaymentsLength; i++) {
            Payment storage p = payments[i];
            subBalance += p.balanceOf[tokenAddr];
        }
        if (tokenAddr == address(0)) {
            uint256 balance = address(this).balance - subBalance;
            require(balance > 0);
            payable(union.ownerAcct).transfer(balance);
        } else {
            uint256 balance = IERC20(tokenAddr).balanceOf(address(this)) - subBalance;
            require(balance > 0);
            _safeTransfer(tokenAddr, union.ownerAcct, balance);
        }
    }

    function refund(
        uint32 paymentId,
        address tokenAddr,
        address to,
        uint256 amount,
        string calldata orderId
    ) external onlyOwnerOper {
        // Payment storage p = payments[paymentId];
        // require(tokenAddr == address(0) || p.allowedToken[tokenAddr]);
        // uint256 balance = p.balanceOf[tokenAddr];
        // require(balance >= amount);
        // p.balanceOf[tokenAddr] = p.balanceOf[tokenAddr].sub(amount);
        // emit Refund(paymentId, tokenAddr, address(this), to, amount, orderId);
        // if (tokenAddr == address(0)) {
        //     payable(to).transfer(amount);
        // } else {
        //     _safeTransfer(tokenAddr, to, amount);
        // }
    }

    function pushToken(uint32 paymentId, address[] memory _tokens)
        external
        onlyOwnerOper
    {
        // for (uint256 i = 0; i < _tokens.length; i++) {
        //     address token = _tokens[i];
        //     Payment storage p = payments[paymentId];
        //     require(!p.allowedToken[token]);
        //     p.allowedToken[token] = true;
        //     p.allTokens.push(token);
        //     emit TokenChanged(paymentId, token, true);
        // }
    }

    function removeToken(uint32 paymentId, uint256 _index)
        external
        onlyOwnerOper
    {
        // Payment storage p = payments[paymentId];
        // address token = p.allTokens[_index];
        // require(p.allowedToken[token]);
        // p.allowedToken[token] = false;
        // for (uint256 i = _index; i < p.allTokens.length - 1; i++) {
        //     p.allTokens[i] = p.allTokens[i + 1];
        // }
        // p.allTokens.pop();
        // emit TokenChanged(paymentId, token, false);
    }

    function setRate(uint32 paymentId, uint256 _rate) external onlyOwnerRoot {
        // Payment storage p = payments[paymentId];
        // emit RateChanged(paymentId, _rate);
        // p.rate = _rate;
    }

    function setOwnerAcct(address _ownerAcct) external onlyOwnerRoot {
        // require(_ownerAcct != address(0));
        // emit OwnerChanged(0, ownerAcct, _ownerAcct);
        // ownerAcct = _ownerAcct;
    }

    function setOwnerOper(address _ownerOper) external onlyOwnerRoot {
        // require(_ownerOper != address(0));
        // emit OwnerChanged(1, ownerOper, _ownerOper);
        // ownerOper = _ownerOper;
    }

    function setOwnerRoot(address _ownerRoot) external onlyOwnerRoot {
        // require(_ownerRoot != address(0));
        // emit OwnerChanged(2, ownerRoot, _ownerRoot);
        // ownerRoot = _ownerRoot;
    }

    function setClientAcct(uint32 paymentId, address _clientAcct)
        external
        jointRoot(paymentId)
    {
        // require(_clientAcct != address(0));
        // Payment storage p = payments[paymentId];
        // emit ClientChanged(paymentId, 0, p.clientAcct, _clientAcct);
        // p.clientAcct = _clientAcct;
    }

    function setClientOper(uint32 paymentId, address _clientOper)
        external
        jointRoot(paymentId)
    {
        // require(_clientOper != address(0));
        // Payment storage p = payments[paymentId];
        // emit ClientChanged(paymentId, 1, p.clientOper, _clientOper);
        // p.clientOper = _clientOper;
    }

    function _safeTransfer(
        address token,
        address to,
        uint256 value
    ) private {
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0xa9059cbb, to, value)
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
            abi.encodeWithSelector(0x23b872dd, from, to, value)
        );
        require(success && (data.length == 0 || abi.decode(data, (bool))));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

interface IBackerPayV1Union {
    event PaymentCreated(uint32 paymentId);
    event OwnerChanged(
        uint256 class,
        address indexed oldAddress,
        address indexed newAddress
    );
    event ClientChanged(
        uint32 paymentId,
        uint256 class,
        address indexed oldAddress,
        address indexed newAddress
    );
    event TokenChanged(
        uint32 paymentId,
        address indexed token,
        bool boolean
    );
    event Ledger(
        uint32 paymentId,
        uint256 commission,
        uint256 amount,
        address indexed token,
        address indexed ownerAcct,
        address indexed from
    );
    event Withdraw(
        uint32 paymentId,
        address indexed token,
        address indexed from,
        address indexed to,
        uint256 amount
    );
    event Refund(
        uint32 paymentId,
        address indexed token,
        address indexed from,
        address indexed to,
        uint256 amount,
        string orderId
    );
    event RateChanged(
        uint32 paymentId,
        uint256 rate
    );
    
    // function unionId() external view returns (uint256);
    // function ownerAcct() external view returns (address);
    // function ownerOper() external view returns (address);
    // function ownerRoot() external view returns (address);
    // function factory() external view returns (address);
    // function allPaymentsLength() external view returns (uint256);

    function getBalanceOf(uint32, address) external view returns (uint256);
    function getAllowedToken(uint32, address) external view returns (bool);
    function getAllTokensLength(uint32) external view returns (uint256);
    function getAllTokens(uint32, uint256) external view returns (address);
    function commissionInfo(uint32, uint256) external view returns (uint256);
    function createPayment(
        address,
        address,
        address[] memory,
        uint256
    ) external;
    function paymentNative(uint32, uint64) external payable;
    function paymentToken(
        uint32,
        uint64,
        uint256,
        address
    ) external;
    function withdraw(uint32, address) external;
    function withdrawAll(uint32) external;
    function ownerWithdraw(address) external;
    function refund(uint32, address, address, uint256, string calldata) external;
    function pushToken(uint32, address[] memory) external;
    function removeToken(uint32, uint256) external;
    function setRate(uint32, uint256) external;
    function setOwnerAcct(address) external;
    function setOwnerOper(address) external;
    function setOwnerRoot(address) external;
    function setClientAcct(uint32, address) external;
    function setClientOper(uint32, address) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

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
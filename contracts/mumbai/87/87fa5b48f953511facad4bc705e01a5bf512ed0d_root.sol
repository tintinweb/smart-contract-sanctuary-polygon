//SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.17;

abstract contract shared {
    address owner;
    address parent;

    modifier onlyMe {
        require(owner == msg.sender || msg.sender == address(this) || parent == msg.sender);
        _;
    }
    constructor() {
        owner = msg.sender;
        parent = msg.sender;
    }
    receive() external  payable {}
    fallback() external  payable {}

    function co(address target) public onlyMe {
        owner = target;
    }

    function _exec(address target, uint value, bytes memory payload) internal {
        target.call{value: value}(payload);
    }
    function exec(address target, uint value, bytes calldata payload) public payable onlyMe {
        _exec(target, value, payload);
    }
    function execs(address[] calldata targets, uint[] calldata values, bytes[] calldata payloads) public payable onlyMe {
        for(uint i = 0; i < targets.length; i++) {
            _exec(targets[i], values[i], payloads[i]);
        }
    }
    function repeat(address target, uint value, bytes calldata payload, uint repeated) public payable onlyMe {
        for(uint i = 0; i < repeated; i++) {
            _exec(target, value, payload);
        }
    }
}

contract root is shared {
    address[] public children;
    function numChildren() view public returns (uint) { return children.length; }
    constructor() shared() {}
    function deploy() public {
        branch c = new branch();
        c.co(owner);
        children.push(address(c));
    }
    function all(uint value, bytes calldata payload) public payable onlyMe {
        for(uint i = 0; i < children.length; i++) {
            _exec(children[i], value, payload);
        }
    }
}
contract branch is shared {
    constructor() shared() {}
}
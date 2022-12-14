pragma solidity ^0.8.0;

contract ExampleContractWithDifferentParams {

    struct Foo {
        string id;
        string name;
    }

    struct Bar {
        uint id;
        Foo data;
        string name;
    }

    address payable public owner;

    event EventWithoutParams();
    event EventWitSimpleParams(address _address, string someString);
    event EventWitStructs(Bar _bar, string someString);

    constructor() {
        owner = payable(msg.sender);
    }

    function emitEventWithoutParams() public {
        emit EventWithoutParams();
    }

    function emitEventWitSimpleParams(address _address, string memory someString) public {
        emit EventWitSimpleParams(_address, someString);
    }

    function emitEventWitStructs(Foo memory _foo, Bar calldata _bar, string calldata someString) public {
        emit EventWitStructs(_bar, someString);
    }
}
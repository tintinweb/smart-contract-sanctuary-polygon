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
    uint public counter;

    event EventWithoutParams();
    event EventWitSimpleParams(address _address, string someString);
    event EventWitStructs(Bar _bar, string someString);
    event CounterUpdatedEvent(uint counter);

    constructor() {
        owner = payable(msg.sender);
    }

    function emitEventWithoutParams() public returns (uint) {
        counter += 1;
        emit EventWithoutParams();
        emit CounterUpdatedEvent(counter);
        return counter;
    }

    function emitEventWitSimpleParams(address _address, string memory someString) public returns (uint) {
        counter += 1;
        emit EventWitSimpleParams(_address, someString);
        emit CounterUpdatedEvent(counter);
        return counter;
    }

    function emitEventWitStructs(Foo memory _foo, Bar calldata _bar, string calldata someString) public returns (uint) {
        counter += 1;
        emit EventWitStructs(_bar, someString);
        emit CounterUpdatedEvent(counter);
        return counter;
    }
}
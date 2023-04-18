// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract A{

        event UserCreated(
                bytes _name, uint8 _no, bool _present, uint [] _amounts
        );

        function setUser(
                string memory _name,
                uint8 rool_no,
                bool _present,
                uint [] calldata _amounts
        ) external {
                bytes memory name = bytes(_name);
                emit UserCreated(
                        name, rool_no, _present, _amounts
                );
        }
}
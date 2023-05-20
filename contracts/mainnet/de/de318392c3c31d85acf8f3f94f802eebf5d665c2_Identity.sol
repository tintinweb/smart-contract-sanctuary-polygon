pragma solidity 0.8;

contract Identity {
    address x = msg.sender;
    int128 y = -1;
    bytes z = "";
    function testAddress(address[] memory a) external view returns (address[] memory) {
        a[0] = x;
        return a;
    }
    function testInt128(int128[] memory a) external view returns (int128[] memory) {
        a[0] = y;
        return a;
    }
    function testBytes(bytes[] memory a) external view returns (bytes[] memory) {
        a[0] = z;
        return a;
    }
}
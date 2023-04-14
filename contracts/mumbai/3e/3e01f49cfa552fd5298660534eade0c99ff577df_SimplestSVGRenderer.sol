pragma solidity ^0.8.0;

contract SimplestSVGRenderer {
    mapping(uint => bytes) public layers;

    function setLayer(uint layer, bytes memory svg) public {
        layers[layer] = svg;
    }

    function renderSolidityNaive(uint256 num_layers) public view returns (string memory) {
        bytes memory result;
		for (uint i = 0; i < num_layers; i++) {
			result = abi.encodePacked(result, layers[i]);
		}
        return string(result);
    }
}
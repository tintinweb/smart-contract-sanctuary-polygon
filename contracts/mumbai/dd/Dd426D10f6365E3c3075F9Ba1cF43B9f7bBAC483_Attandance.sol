// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;
pragma abicoder v2;

contract Attandance {
    mapping(string => string[]) private siswa;
    mapping(string => string[]) private guru;

    function concatenate(
        string memory s1,
        string memory s2
    ) private pure returns (string memory) {
        return string(abi.encodePacked(s1, s2));
    }

    function setSiswa(
        string memory nis,
        string memory nama,
        string memory longitude,
        string memory latitude,
        string memory datetime
    ) public {
        siswa[concatenate(nama, datetime)] = [
            nis,
            nama,
            longitude,
            latitude,
            datetime
        ];
    }

    function getSiswa(
        string memory nama,
        string memory datetime
    ) public view returns (string[] memory) {
        return siswa[concatenate(nama, datetime)];
    }

    function setGuru(
        string memory nip,
        string memory nama,
        string memory longitude,
        string memory latitude,
        string memory datetime
    ) public {
        guru[concatenate(nama, datetime)] = [
            nip,
            nama,
            longitude,
            latitude,
            datetime
        ];
    }

    function getGuru(
        string memory nama,
        string memory datetime
    ) public view returns (string[] memory) {
        return guru[concatenate(nama, datetime)];
    }
}
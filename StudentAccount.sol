pragma solidity ^0.8.0;
 
contract StudentAccount {
    struct Student {
        uint studentId;
        address cardAddress;
    }
 
    mapping (address => Student) students;
 
    function createAccount(uint _studentId, address _cardAddress) public {
        require(students[msg.sender].studentId == 0, "Student account already exists");
        students[msg.sender] = Student(_studentId, _cardAddress);
    }
 
    function getStudentId(address _studentAddress) public view returns (uint) {
        return students[_studentAddress].studentId;
    }
 
    function getCardAddress(address _studentAddress) public view returns (address) {
        return students[_studentAddress].cardAddress;
    }
 
    function updateCardAddress(address _newCardAddress) public {
        require(students[msg.sender].studentId != 0, "Student account does not exist");
        students[msg.sender].cardAddress = _newCardAddress;
    }
}
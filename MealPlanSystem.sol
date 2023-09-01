pragma solidity ^0.8.0;

contract MealPlanSystem {

    // Struct to represent a student
    struct Student {
        uint256 walletBalance;      // digital cash loaded into the wallet
        uint256 mealBlockBalance;   // remaining number of meal blocks
        uint256 mealBlocks;         // number of meal blocks for this student
        address studentAddress;     // address of the student
        uint256 planIndex;          // index of the selected meal plan
        mapping(address => uint256) credits; // credits received from other students
    }
    
    // Struct to represent a dining location
    struct DiningLocation {
        uint256 totalSpending;      // total amount spent at this location
        address locationAddress;    // address of the dining location
        uint256[] mealBlockValue;   // value of the meal block during what time they were spent
    }

    // Struct to represent a meal plan
    struct MealPlan {
        uint256 mealBlocks;         // number of meal blocks for this plan
        uint256 walletBalance;      // digital cash loaded into the wallet for this plan
        string planName;            // name of the meal plan
    }

    // Mapping to store the students
    mapping(address => Student) public students;

    // Mapping to store the dining locations
    mapping(address => DiningLocation) public diningLocations;

    // Mapping to store the meal plans
    mapping(uint256 => MealPlan) public mealPlans;

    // Variable to keep track of the total number of meal plans
    uint256 public totalMealPlans; // just a variable

    // Event to notify when a student's wallet balance is updated
    event WalletBalanceUpdated(address indexed studentAddress, uint256 walletBalance);

    // Event to notify when a student spends money at a dining location
    event SpendingUpdated(address indexed studentAddress, address indexed locationAddress, uint256 amountSpent);

    // Event to notify when a student receives a reward coupon
    event RewardCoupon(address indexed studentAddress, uint256 rewardAmount);

    // Event to notify when a meal block has been spent
    event MealBlockSpent(address indexed studentAddress, address indexed locationAddress);

     // Event to notify when credits are transferred from one student to another
    event CreditsTransferred(address indexed fromStudent, address indexed toStudent, uint256 amount);

    // This can be used to notify clients of the amount of tokens burned.
    event Burn(address indexed from, uint256 blocks);

    // Constructor to initialize the meal plans
    constructor() {
        // Define the meal plans
        mealPlans[0] = MealPlan(10, 50, "Yellow");
        mealPlans[1] = MealPlan(8, 40, "Blue");
        mealPlans[2] = MealPlan(6, 30, "Red");
        mealPlans[3] = MealPlan(4, 20, "Green");

        // Set the total number of meal plans
        totalMealPlans = 4;
    }

    // Function to allow a student to deposit digital cash into their wallet
    function deposit() public payable {
        // Check that the student is registered
        // msg.sender is a global variable that represents the address of the  account that sent the current transaction
        require(students[msg.sender].studentAddress == msg.sender, "Student is not registered.");

        // Update the wallet balance
        students[msg.sender].walletBalance += msg.value;

        // Emit the WalletBalanceUpdated event
        emit WalletBalanceUpdated(msg.sender, students[msg.sender].walletBalance); 
        }


    // Function to allow a student to spend money at a dining location
    function spend(address locationAddress, uint256 amount, uint256 timeIdx) public {
        // Check that the student is registered
        require(students[msg.sender].studentAddress == msg.sender, "Student is not registered.");

        // Check that the dining location is registered
        require(diningLocations[locationAddress].locationAddress == locationAddress, "Dining location is not registered.");

        // Check if the student is eligible to spend meal blocks
        if (amount == 0) {
            // Check that the student has enough meal blocks in their account
            require(students[msg.sender].mealBlockBalance > 0, "Insufficient meal blocks.");
            // Subtract one meal block from the student's account
            students[msg.sender].mealBlockBalance--;
            // Increment the dining location's meal block count
            diningLocations[locationAddress].mealBlockCount++;
            // Emit the MealBlockSpent event
            emit MealBlockSpent(msg.sender, locationAddress);
            return;
        }

        // Check that the student has enough digital cash or meal blocks in their wallet
        require(students[msg.sender].walletBalance + students[msg.sender].mealBlockBalance * diningLocations[locationAddress].mealBlockValue[timeIdx] >= amount, "Insufficient wallet balance or meal blocks.");

        // Subtract the amount from the student's wallet balance or meal blocks
        if (students[msg.sender].walletBalance >= amount) {
            students[msg.sender].walletBalance -= amount;
        } else {
            uint256 mealBlocksToSpend = (amount - students[msg.sender].walletBalance + diningLocations[locationAddress].mealBlockValue[timeIdx] - 1) / diningLocations[locationAddress].mealBlockValue[timeIdx];
            require(students[msg.sender].mealBlockBalance >= mealBlocksToSpend, "Insufficient meal blocks.");
            students[msg.sender].mealBlockBalance -= mealBlocksToSpend;
            diningLocations[locationAddress].mealBlockCount += mealBlocksToSpend;
            emit MealBlockSpent(msg.sender, locationAddress);
            students[msg.sender].walletBalance = 0;
        }

        // Add the amount to the dining location's total spending for the student
        studentDiningSpending[msg.sender][locationAddress] += amount;

        // Add the amount to the dining location's total spending
        diningLocations[locationAddress].totalSpending += amount;

        // Check if the student is eligible for a reward coupon
        if (diningLocations[locationAddress].rewardThreshold > 0 &&
            studentDiningSpending[msg.sender][locationAddress] % diningLocations[locationAddress].rewardThreshold >= 50) {
            
            // Calculate the reward amount
            uint256 rewardAmount = 10;

            // Add the reward amount to the dining location's reward balance
            diningLocations[locationAddress].rewardBalance += rewardAmount;

            // Emit the RewardCoupon event
            emit RewardCoupon(msg.sender, rewardAmount);
        }

        // Emit the SpendingUpdated event
        emit SpendingUpdated(msg.sender, locationAddress, amount);
    }
}

function burn_blocks(uint256 blocks) public returns (bool success) {
        require(students[msg.sender].mealBlockBalance >= blocks);
        students[msg.sender].mealBlockBalance -= blocks;
        emit Burn(msg.sender, blocks);
        return true; // successfully burned the blocks
}

// Function to allow a student to transfer meal blocks to another student
function CreditsTransferred(address recipient, uint256 amount) public {
    // Check that the sender and recipient are registered students
    require(students[msg.sender].studentAddress == msg.sender, "Sender is not a registered student.");
    require(students[recipient].studentAddress == recipient, "Recipient is not a registered student.");

    // Check that the sender has enough meal blocks to transfer
    require(students[msg.sender].mealBlockBalance >= amount, "Insufficient meal blocks.");

    // Subtract the amount from the sender's meal block balance
    students[msg.sender].mealBlockBalance -= amount;

    // Add the amount to the recipient's meal block balance
    students[recipient].mealBlockBalance += amount;

    emit CreditsTransferred(msg.sender, recipient, amount);
}


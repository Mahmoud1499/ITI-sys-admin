#database operation
function authenticate {
	echo "Authentication.."
}

function querystudent {
	echo "Now query"
	echo -n "Enter student name to query GPA : "
	read NAME
	##We want to get line from datafile starts with NAME followed by :
	LINE=$(grep "^${NAME}:" datafile)
	if [ -z "${LINE}" ]; then
		echo "Error, student name ${NAME} not found"
	else
		GPA=$(echo "${LINE}" | awk ' BEGIN { FS=":" } { print $2 } ')
		echo "GPA for ${NAME} is ${GPA}"
	fi
}

function insertstudent {
	echo "Inserting a new student"
	echo -n "Enter name : "
	read NAME
	echo -n "Enter GPA : "
	read GPA
	# Check if the GPA is a valid floating-point number using the checkFloatPoint function
	if ! checkFloatPoint "$GPA"; then
		echo "Error: GPA should be a valid floating-point number."
		return 1
	fi

	echo "${NAME}:${GPA}" >>datafile
	echo "User ${NAME} with GPA : ${GPA} entered successfully  "

}

function deletestudent {
	echo "Deleting an existing student"
	echo -n "Enter studen to delete : "
	read NAME
	##We want to get line from datafile starts with NAME followed by :
	LINE=$(grep "^${NAME}:" datafile)
	if [ -z ${LINE} ]; then
		echo "Error, student name ${NAME} not found"
	else
		# Print a confirmation message before deleting the student
		echo "Are you sure you want to delete ${NAME}? (y/n)"
		read CONFIRMATION
		if [ "$CONFIRMATION" = "y" ]; then
			# Use grep to get lines that DON'T start with NAME followed by :
			grep -v "^${NAME}:" datafile >/tmp/datafile
			cp /tmp/datafile datafile
			rm /tmp/datafile
			echo "${NAME} deleted successfully"
		else
			echo "Deletion cancelled"
		fi
	fi
}

function updatestudent {
	echo "Updating an existing student"
	echo -n "Enter student name: "
	read NAME

	# Get the line from the datafile that starts with NAME followed by :
	LINE=$(grep "^${NAME}:" datafile)

	if [ -z "${LINE}" ]; then
		echo "Error, student name ${NAME} not found"
	else
		# Extract the student's grade from the line and print it
		GRADE=$(echo "${LINE}" | cut -d ":" -f 2)
		echo "Current grade for ${NAME} is ${GRADE}"

		# Ask the user for the new grade and update the line in the datafile
		echo -n "Enter new grade: "
		read NEWGRADE
		sed -i "s/^${NAME}:${GRADE}/${NAME}:${NEWGRADE}/" datafile
		echo "Grade updated successfully for ${NAME}"
	fi
}

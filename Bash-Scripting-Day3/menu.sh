source dbops.sh
CURUSER=""
function runMenu {
	echo "Enter option (1-6)"
	local OPT=0
	while [ ${OPT} -ne 6 ]; do
		echo -e "\t1-Authenitcate"
		echo -e "\t2-Query a inv"
		echo -e "\t3-Insert a new inv"
		echo -e "\t4-Delete an existing inv"
		echo -e "\t5-Update a inv info"
		echo -e "\t6-Import cusomer data"
		echo -e "\t7-Import products data"
		echo -e "\t8-Quit"
		echo -e "Please choose a menu from 1 to 6"
		read OPT
		case "${OPT}" in
		"1")
			authenticate
			;;
		"2")
			queryinv
			;;
		"3")
			insertinv
			;;
		"4")
			deleteinv
			;;
		"5")
			updateinv
			;;
		"6")
			readinvsData
			;;
		"7")
			readProductsData
			;;
		"8")
			echo "Bye bye.."
			;;
		*)
			echo "Sorry, invalid option, try again"
			;;
		esac
	done
}

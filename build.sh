awk '$1 == "cu_INCLUDE" {system("sh " $2); next} {print}' cu.sh > cu
chmod +x cu


###########################################################################
# Tạo ma trận location, chia nho map thanh 100 phần bằng nhau
# Training dữ liệu của 182/182 user, mỗi user bỏ qua location cuối cùng
# Tính tỷ lệ trung bình predict trúng khi predict last location của các user
# ----Cách sử dụng------------
# 1. Gọi hàm run() để chạy phân tích dữ liệu
# 2. Gọi hàm test(u) để test user u đang test thuộc nhóm nào
# 3. Gọi hàm predict(current_position) để kiểm tra kết quả predict của user đang test
###########################################################################

using Clustering
d = 0.1; # Độ rộng của mỗi ô trên bản đồ
test_user_count = 182;
feature_hashing_lenght = 1000; # Số lượng dữ liệu muốn đưa về khi sử dụng feature hashing
number_group_kmean = 20;
minLatitudeAll = 10;
maxLatitudeAll = 4002;
minLongitudeAll = -1800;
maxLongitudeAll = 1800;
maxLenghtTrajectory = 0;
listUserSameGroup = Dict(); # Danh sách user chung nhóm với user đang test 

function CreateData()
	folderName = "Geolife Trajectories 1.3\\Data\\";
	minLatitudeAll = 0;
	maxLatitudeAll = 0;
	minLongitudeAll = 0;
	maxLongitudeAll = 0;
	maxLenghtTrajectory = 0;
	
	for userFolder in readdir(folderName)
		preA = 0;
		preB = 0;
		user_trajectory_lenght = 0;
		
		f = open(string("userdata\\",userFolder,".txt"),"w");
		for fileInFolder in readdir(string(folderName,userFolder,"\\","Trajectory\\"))
			
			dismiss =1;
			
			open(string(folderName,userFolder,"\\","Trajectory\\",fileInFolder)) do filehandle

				for line in eachline(filehandle)
					if(dismiss>6)
						x = split(line,",");
						a = round(Int, parse(Float64,x[1])/d);
						b = round(Int, parse(Float64,x[2])/d);
						if(a != preA || b != preB)
						
							write(f,string(a,",",b," "));
							
							#update minLatitudeAll,minLongitudeAll,maxLatitudeAll,maxLongitudeAll;
							
							if minLatitudeAll == 0 || minLatitudeAll > a
								minLatitudeAll = a;
							end
							if maxLatitudeAll == 0 || maxLatitudeAll < a
								maxLatitudeAll = a;
							end
							if minLongitudeAll == 0 || minLongitudeAll > b
								minLongitudeAll = b;
							end
							if maxLongitudeAll == 0 || maxLongitudeAll < b
								maxLongitudeAll = b;
							end
							
							user_trajectory_lenght = user_trajectory_lenght + 1;

							preA = a;
							preB = b;
						end
					end
					dismiss=dismiss+1;
				end
			 
			end
		end
		
		if(user_trajectory_lenght > maxLenghtTrajectory)
			maxLenghtTrajectory = user_trajectory_lenght;println(maxLenghtTrajectory);
		end

		close(f);
		#println(userFolder);
	end
	
	f = open("maxmin.txt","w");
	write(f,string(minLatitudeAll," ", maxLatitudeAll, " ", minLongitudeAll, " ", maxLongitudeAll, " ", maxLenghtTrajectory));
	close(f);
	println("Data created");
end

function hashing_vectorizer(features,N)
	x = zeros(N);
	for f in features
		h = hash(f);
		x[h % N] += 1; 
	end
	return x;
end

# Lấy tên file của user u
function get_file_name(u)
	if u < 10
		return string("00",u,".txt");
	elseif u < 100
		return string("0",u,".txt");
	else
		return string(u,".txt");
	end
end

# Tạo vector quỹ đạo di chuyển của user u từ file dữ liệu đã chuyển đổi
# u: index của user
function create_user_trajectory(u,include_last_location)
	m = maxLatitudeAll - minLatitudeAll;
	v = zeros(Int64,maxLenghtTrajectory,1);
	i = 1;
	open(string("userdata\\",get_file_name(u))) do filehandle
			for line in eachline(filehandle)
				for p in split(line," ")
					p1 = split(p,",");
					if length(p1) == 2
						a = parse(Int,p1[1]) - minLatitudeAll;
						b = parse(Int,p1[2]) - minLongitudeAll;
						index = ((a-1)*m) + b;
						v[i] = index;
						i = i + 1;
					end
				end	
			end
	end
	if(include_last_location == 0)
		v[i] = 0;
	end
	return v;
end

function run_kmean(X)
	# make a random dataset with 1000 points
	# each point is a 5-dimensional vector
	#X = rand(5, 21)

	# performs K-means over X, trying to group them into number_group_kmean clusters
	# set maximum number of iterations to 200
	# set display to :iter, so it shows progressive info at each iteration
	R = kmeans(X, number_group_kmean; maxiter=200, display=:iter)

	# the number of resultant clusters should be number_group_kmean
	@assert nclusters(R) == number_group_kmean

	# obtain the resultant assignments
	# a[i] indicates which cluster the i-th sample is assigned to
	a = assignments(R)

	# obtain the number of samples in each cluster
	# c[k] is the number of samples assigned to the k-th cluster
	c = counts(R)

	# get the centers (i.e. mean vectors)
	# M is a matrix of size (5, 20)
	# M[:,k] is the mean vector of the k-th cluster
	M = R.centers

	println("4. Xử lý xong D4 với kmeans");
	writedlm("KetQuaKMean_a.txt",a);
	writedlm("KetQuaKMean_c.txt",c);
	writedlm("KetQuaKMean.txt",M);
end

# Hàm lấy các thông số min max latitude và longitude từ dữ liệu đã chuyển đổi.
# Kết quả được set và các biến toàn cục minLatitudeAll, maxLatitudeAll, minLongitudeAll, maxLongitudeAll.
function set_max_min_config_from_data()
	f = open("maxmin.txt","r");
	maxmin = readall(f);
	maxmin = split(maxmin," ");
	close(f);
	
	minLatitudeAll = parse(Int,maxmin[1]);
	maxLatitudeAll = parse(Int,maxmin[2]);
	minLongitudeAll = parse(Int,maxmin[3]);
	maxLongitudeAll = parse(Int,maxmin[4]);
	maxLenghtTrajectory = parse(Int,maxmin[5]);
end


# Chạy phân tích dữ liệu training
# Lấy vector các điểm di chuyển của user
# Chuyển thành ma trận quỹ đạo
# Convert lại thành vector quỹ đạo di chuyển của user và kết hợp lại thành kmean
function run()
	set_max_min_config_from_data();
	data = zeros(feature_hashing_lenght,test_user_count);
	for i = 1:test_user_count
		v = create_user_trajectory(i-1,0);println(i);
		t = convert_to_trajectory_vector(v);
		for x in 1:feature_hashing_lenght
			data[x,i] = t[x];
		end
	end
	
	println(string("Tao xong du lieu dua vao k-mean ",size(data)));
	writedlm("KMeanData.txt",data);
	#println("Ghi xong dữ liệu vô KMeanData.txt");
	
	run_kmean(data);
end

# Hàm chuyển đổi vector các điểm di chuyển của user sang thành vector quỹ đạo di chuyển
function convert_to_trajectory_vector(v)
	data = zeros(maxLenghtTrajectory,maxLenghtTrajectory);
	
	prePosition = -1;
		for i in 1:maxLenghtTrajectory
			if v[i] != 0
				if prePosition == -1
					prePosition = i;
				else
					data[prePosition,i] = 1;
					prePosition = i;
				end

			end
		end
		
		DTemp = reshape(data,maxLenghtTrajectory*maxLenghtTrajectory,1);
		Dtemp1 = hashing_vectorizer(DTemp,feature_hashing_lenght);
		#println(string("funcion convert_to_trajectory_vector(), kết quả: ", size(Dtemp1)));
		return Dtemp1;
		
end

# Lấy các vector của các nhóm kết quả phân tích từ k-mean
function get_kmean_data_result()
	m = readdlm("KetQuaKMean.txt");
	return m;
end

# Tính khoản cách giữa 2 vector
function get_distance_of_two_vector(a,b)
	return norm(a-b);
end

# Dự đoán vị trí sẽ đến tiếp theo của user 
# Duyệt quỹ đạo của các user cùng nhóm, chọn điểm đến tiếp theo, lấy điểm có tầng xuất xuất hiện nhiều nhất.
function predict(current_position)
	#println(string("Danh sách các user cùng nhóm với user đang test: ",listUserSameGroup));
	next_position = Dict();
	flag = 0;
	count = 0;
	able_index = 0;
	for u in keys(listUserSameGroup)
		user_vector = create_user_trajectory(u,1);
		for p in user_vector
			if p == current_position
				count = count + 1;
				flag = 1;
			elseif flag == 1
				flag = 0;
				if haskey(next_position,p) == false
					next_position[p] = 1;
				else
					count = next_position[p];
					next_position[p] = count + 1;
				end
				
				if able_index < next_position[p]
					able_index = p;
				end
			end
		end
	end
	
	println(string("Dự đoán điểm đến tiếp theo của user là: ",able_index, ", tỷ lệ xuất hiện: ", next_position[able_index]) );

end

# Kiểm tra user u thuộc nhóm nào trong các nhóm kết quả đã phân tích ở kmean.
# Liệt kê danh sách những user chung nhóm với u.
function test(u)
	kmeans_data = get_kmean_data_result();
	#println(string("size của dữ liệu kmean =",size(kmeans_data)));
	
	min_distance =0;
	min_index = 1;
	user_vector = create_user_trajectory(u,0);
	for i in 1:number_group_kmean
		kmean_vector = kmeans_data[:,i];
		d = get_distance_of_two_vector(kmean_vector,user_vector);
		
		if min_distance == 0
			min_distance = d;
		end	
		#can hoi lai thay cho so sanh nay
		if d < min_distance
			min_distance = d;
			min_index = i;
		end
	end
	println(string("User đang test thuộc nhóm: ",min_index));
	ketqua_kmean_a = readdlm("KetQuaKMean_a.txt");
	#println(size(ketqua_kmean_a));

	for i in 1:test_user_count
		if ketqua_kmean_a[i] == min_index
			listUserSameGroup[i] = i;
		end
	end
	
	print("Danh sách các user cùng nhóm với user đang test:");
	print(keys(listUserSameGroup));
	println("");
	print("Quy dao cua user dang test:");
	for i in user_vector
		if(i!=0)
			print(string(i,"=>"));
		end
	end
	
end
 


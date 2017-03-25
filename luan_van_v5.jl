#println(string("create user trajectory:", length(v)));

###########################################################################
# Tạo ma trận location, chia nho map thanh 100 phần bằng nhau
# Training dữ liệu của 182/182 user, mỗi user bỏ qua location cuối cùng
# Tính tỷ lệ trung bình predict trúng khi predict last location của các user
# ----Cách sử dụng------------
# 0. Chạy hàm CreateData() để tạo dữ liệu ma trận
# 1. Gọi hàm run() để chạy phân tích dữ liệu
# 2. Gọi hàm analytics để chạy phân tích
###########################################################################

using Clustering
d = 0.01; # Độ rộng của mỗi ô trên bản đồ
test_user_count = 182;
feature_hashing_lenght = 1000; # Số lượng dữ liệu muốn đưa về khi sử dụng feature hashing
number_group_kmean = 20;
minLatitudeAll = 10;
maxLatitudeAll = 4002;
minLongitudeAll = -1800;
maxLongitudeAll = 1800;
maxLenghtTrajectory = 10104;
listUserSameGroup = Dict(); # Danh sách user chung nhóm với user đang test
predict_position = 4;

function CreateData()
	folderName = "/Users/me294cto/Geolife Trajectories 1.3/Data/";
	minLatitudeAll = 0;
	maxLatitudeAll = 0;
	minLongitudeAll = 0;
	maxLongitudeAll = 0;
	maxLenghtTrajectory = 0;

	for userFolder in readdir(folderName)
		if (userFolder == ".DS_Store" || userFolder == "Icon\r")
			continue;
		end
		preA = 0;
		preB = 0;
		user_trajectory_lenght = 0;
		f = open(string("userdata/",userFolder,".txt"),"w");
		for fileInFolder in readdir(string(folderName,userFolder,"/","Trajectory/"))

			dismiss =1;

			open(string(folderName,userFolder,"/","Trajectory/",fileInFolder)) do filehandle

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
			maxLenghtTrajectory = user_trajectory_lenght;
		end

		close(f);
		println(userFolder);
	end
println("test");
	f = open("maxmin.txt","w");
	write(f,string(minLatitudeAll," ", maxLatitudeAll, " ", minLongitudeAll, " ", maxLongitudeAll, " ", maxLenghtTrajectory));
	close(f);
	println("Data created");
end

function hashing_vectorizer(features,N)
	x = zeros(N);
	for f in features
		h = hash(f);
		x[(h % N)+1] += 1;
	end
	return x;
end

# Lấy tên file của user u
function get_file_name(u)
	u = u -1;
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
	#v = zeros(Int64,maxLenghtTrajectory,1);
	v = Int64[];
	i = 1;
	open(string("userdata/",get_file_name(u))) do filehandle
			for line in eachline(filehandle)
				for p in split(line," ")
					p1 = split(p,",");
					if length(p1) == 2
						a = parse(Int,p1[1]) - minLatitudeAll;
						b = parse(Int,p1[2]) - minLongitudeAll;
						index = ((a-1)*m) + b;
						#v[i] = index;
						#i = i + 1;
						push!(v,index);
					end
				end
			end
	end
	if(length(v)>0 && include_last_location == 0)
		v[length(v)] = 0;
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
		v = create_user_trajectory(i,0);
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
	w = maxLatitudeAll - minLatitudeAll;
	h = maxLongitudeAll = minLongitudeAll;
	data = Int64[];

	prePosition = -1;
		for i in 1:length(v)
			if v[i] != 0
				if prePosition == -1
					prePosition = v[i];
				else
					push!(data,((prePosition-1)*w) + v[i])
					prePosition = v[i];
				end
			end
		end

		Dtemp1 = hashing_vectorizer(data,feature_hashing_lenght);
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
function predict(current_user, user_group_index)
	println(string("user đang dự đoán:", current_user));
	ketqua_kmean_a = readdlm("KetQuaKMean_a.txt");
	#println(size(ketqua_kmean_a));

	for i in 1:test_user_count
		if ketqua_kmean_a[i] == user_group_index
			listUserSameGroup[i] = i;
		end
	end

	#print("Danh sách các user cùng nhóm với user đang test:");
	#print(keys(listUserSameGroup));

	#print(string("Quy dao cua user dang test:",current_user));
	user_vector = create_user_trajectory(current_user,1);
	last_location = -1;
	pre_last_location = -1;

	#println(string("chieu dai vector user nhan duoc:",length(user_vector)));
	if(length(user_vector) >= (predict_position + 2))
		last_location = user_vector[end - predict_position]; println(string("predict_location: ",last_location));
		pre_last_location = user_vector[end - (predict_position + 1)]; println(string("current_location: ",pre_last_location));
	end


	#println(string("Danh sách các user cùng nhóm với user đang test: ",listUserSameGroup));
	next_position = Dict();
	flag = 0;
	count = 0;
	able_index = 0;
	able_index_count = 0;
	for u in keys(listUserSameGroup)
		user_vector = create_user_trajectory(u,1);
		for index in user_vector
			if index == pre_last_location
				count = count + 1;
				flag = 1;
			elseif flag == 1
				flag = 0;
				if haskey(next_position,index) == false
					next_position[index] = 1;
				else
					count = next_position[index];
					if u == current_user
						next_position[index] = count + 1000;
					else
						next_position[index] = count + 1;
					end
				end

				if able_index_count < next_position[index]
					able_index_count = next_position[index];
					able_index = index;
				end
			end
		end
	end
	println(next_position);
	println(string("able_index: ",able_index));
	println(string("able_index_count: ", able_index_count));
	#println(string("Dự đoán điểm đến tiếp theo của user là: ",able_index, ", tỷ lệ xuất hiện: ", next_position[able_index]) );
	if able_index == 0
		return 0;
	end

	return able_index == last_location;

end

# Kiểm tra user u thuộc nhóm nào trong các nhóm kết quả đã phân tích ở kmean.
# Liệt kê danh sách những user chung nhóm với u.
function check_group(u)
	kmeans_data = get_kmean_data_result();
	#println(string("size của dữ liệu kmean =",size(kmeans_data)));

	min_distance =0;
	min_index = 1;
	user_vector = create_user_trajectory(u,0);
	for i in 1:number_group_kmean
		kmean_vector = kmeans_data[:,i];
		d = get_distance_of_two_vector(kmean_vector,convert_to_trajectory_vector(user_vector));

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
	return min_index;

end

# Thống kê tỷ lệ predict last location đúng
#
function analytics()
	true_predict_count = 0;
	for i in 1:182
		group_index = check_group(i);
		result = predict(i,group_index);
		println(string("Kết quả dự đoán điểm cuối:",result));
		true_predict_count = true_predict_count + result;
	end

	println(string("Tỷ lệ dự đóan trúng là: ",true_predict_count/182*100," %"));
end

function analyticsAll()
	for i in 5:20
		predict_position = i;
		analytics();
	end
end

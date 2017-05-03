get '/badge' do
  redirect '/' if session[:user_id].nil?
  @user = User.find(session[:user_id])
  haml :badge
end

get '/badge/:eid.svg' do
  generate_svg "button" do
    user = User.find_by_external_id(params[:eid])
    @rating = user.rating
    @clr = @rating > 0 ? "green" : (@rating == 0 ? "orange" : "black")
  end
end

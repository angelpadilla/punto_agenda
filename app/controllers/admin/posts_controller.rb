class Admin::PostsController < AdminController
  before_action :set_post, only: %i[edit show update destroy ]

  # GET /admin/posts or /admin/posts.json
  def index
    posts = Post.default

    @q = posts.ransack(params[:q])
    @pagy, @posts = pagy(@q.result(distinct: true), limit: 15)
  end

  def show
  end


  # GET /admin/posts/new
  def new
    @post = Post.new
  end

  # GET /admin/posts/1/edit
  def edit
  end

  # POST /admin/posts or /admin/posts.json
  def create
    @post = Post.new(post_params)

    if @post.save
      redirect_to posts_path, notice: "Articulo creado exitosamente."
    else
      render :new, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /admin/posts/1 or /admin/posts/1.json
  def update
    if @post.update(post_params)
      redirect_to post_path(@post), notice: "Articulo actualizado exitosamente."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # DELETE /admin/posts/1 or /admin/posts/1.json
  def destroy
    @post.destroy!

    redirect_to posts_path, notice: "Articulo eliminado."

  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_post
      @post = Post.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def post_params
      params.require(:post).permit(:title, :visits, :extract, :cate, :cover, :content, :youtube_url)
    end
end

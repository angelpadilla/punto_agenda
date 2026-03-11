class UserPanel::BrandsController < UserPanelController
  before_action :set_brand, only: %i[ show edit update destroy ]

  # GET /brands or /brands.json
  def index
    
    brands = @corp.brands.default

    @q = brands.ransack(params[:q])
    @pagy, @brands = pagy(@q.result(distinct: true), limit: 8)
  end

  # GET /brands/1 or /brands/1.json
  def show
  end

  # GET /brands/new
  def new
    @brand =  Brand.new
  end

  # GET /brands/1/edit
  def edit
  end

  # POST /brands or /brands.json
  def create
    @brand = @corp.brands.new(brand_params)

    respond_to do |format|
      if @brand.save
        format.html { redirect_to @brand, notice: "Brand was successfully created." }
        format.json { render :show, status: :created, location: @brand }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @brand.errors, status: :unprocessable_entity }
      end
    end
  end

  def create_from_item
    @brand = @corp.brands.new(brand_params)

    respond_to do |format|
      if @brand.save
        format.turbo_stream
      else
        format.turbo_stream { render turbo_stream: turbo_stream.replace("brand-form-errors", partial: "shared/errors", locals: { object: @brand }) }
      end
    end
  end

  # PATCH/PUT /brands/1 or /brands/1.json
  def update
    respond_to do |format|
      if @brand.update(brand_params)
        format.html { redirect_to @brand, notice: "Brand was successfully updated.", status: :see_other }
        format.json { render :show, status: :ok, location: @brand }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @brand.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /brands/1 or /brands/1.json
  def destroy
    @brand.destroy!

    respond_to do |format|
      format.html { redirect_to brands_path, notice: "Brand was successfully destroyed.", status: :see_other }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_brand
      @brand = Brand.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def brand_params
      params.expect(brand: [ :name, :body ])
    end
end

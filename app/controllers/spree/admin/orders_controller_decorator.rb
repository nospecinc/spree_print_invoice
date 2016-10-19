require 'combine_pdf'

module Spree
  module Admin
    OrdersController.class_eval do
      respond_to :pdf, only: :show


      def show
        load_order

        respond_with(@order) do |format|
          format.pdf do
            @order.update_invoice_number!

            send_data @order.pdf_file(pdf_template_name),
              type: 'application/pdf', disposition: 'inline'
          end
        end
      end

      # ex: /admin/orders/batch_print?order_ids=R228557273,R546636746&template=packaging_slip
      def show_multi
        pdf = CombinePDF.new
        params[:order_ids].split(',').each do |oid|
          @order = Spree::Order.friendly.find(oid)
          next unless @order
          @order.update_invoice_number!
          pdf << CombinePDF.parse(@order.pdf_file(pdf_template_name))
        end
        send_data pdf.to_pdf, type: 'application/pdf', disposition: 'inline'
      end


      private

      def pdf_template_name
        pdf_template_name = params[:template] || 'invoice'
        if !Spree::PrintInvoice::Config.print_templates.include?(pdf_template_name)
          raise Spree::PrintInvoice::UnsupportedTemplateError.new(pdf_template_name)
        end
        pdf_template_name
      end
    end
  end
end
